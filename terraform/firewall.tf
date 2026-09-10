# =====================================================================
# 1. PUBLIEKE IP-ADRESSEN VOOR DE FIREWALL
# =====================================================================
resource "azurerm_public_ip" "fw_pip" {
  name                = "pip-afw-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "fw_mgmt_pip" {
  name                = "pip-afw-mgmt-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# =====================================================================
# 2. AZURE FIREWALL POLICY (Centrale Regels)
# =====================================================================
resource "azurerm_firewall_policy" "fw_policy" {
  name                = "afwp-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  tags                = var.tags
}

# =====================================================================
# 3. AZURE FIREWALL BASIC DEPLOYMENT (Gecorrigeerde Subnets)
# =====================================================================
resource "azurerm_firewall" "fw" {
  name                = "afw-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id
  tags                = var.tags

  # Dataplane: Gekoppeld aan het echte AzureFirewallSubnet
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id 
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  # Managementplane: Gekoppeld aan het echte AzureFirewallManagementSubnet
  management_ip_configuration {
    name                 = "mgmt-configuration"
    subnet_id            = azurerm_subnet.firewall_mgmt.id 
    public_ip_address_id = azurerm_public_ip.fw_mgmt_pip.id
  }
}

# =====================================================================
# 4. FIREWALL POLICY RULE COLLECTION GROUPS (Met Inter-Spoke Rule)
# =====================================================================
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 200

  network_rule_collection {
    name     = "rc-network-shared"
    priority = 100
    action   = "Allow"

    # Regel A: Uitgaande pings naar internet
    rule {
      name                  = "allow-outbound-ping"
      protocols             = ["ICMP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_ports     = ["*"]
      destination_addresses = ["*"]
    }

    # Regel B: Toegevoegd voor jouw gecontroleerde validatie-ping TUSSEN de spokes!
    rule {
      name                  = "allow-interspoke-validation-ping"
      protocols             = ["ICMP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_ports     = ["*"]
      destination_addresses = ["10.1.0.0/16", "10.2.0.0/16"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "app_rules" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 300

  application_rule_collection {
    name     = "rc-apps-shared"
    priority = 110
    action   = "Allow"

    rule {
      name             = "allow-ubuntu-updates"
      source_addresses = ["10.1.0.0/16", "10.2.0.0/16"]
      
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      
      destination_fqdns = ["*.ubuntu.com", "ubuntu.com"]
    }
  }
}
