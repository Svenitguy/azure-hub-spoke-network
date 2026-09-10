# =====================================================================
# 1. NETWORK SECURITY GROUP: SPOKE 1 (PROD)
# =====================================================================
resource "azurerm_network_security_group" "spoke1_prod" {
  name                = "nsg-spoke1-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Rule 120: SSH toestaan UITSLUITEND vanaf het Management Subnet
  security_rule {
    name                       = "Allow-SSH-From-MgmtSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "*"
  }

  # Rule 110: De gecontroleerde uitzondering voor Pings vanaf Spoke 2 Test
  security_rule {
    name                       = "Allow-Ping-From-Firewall"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.2.0.0/16" # Bron: Spoke 2 Test
    destination_address_prefix = "10.1.0.0/16" # Doel: Spoke 1 Prod zelf
  }

  # Rule 130: Harde blokkade voor AL het andere verkeer uit Spoke 2 Test
  security_rule {
    name                       = "Deny-Spoke2-Test-Traffic"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.2.0.0/16"
    destination_address_prefix = "*"
  }
}

# Koppel de NSG aan het subnet van Spoke 1
resource "azurerm_subnet_network_security_group_association" "spoke1_assoc" {
  subnet_id                 = azurerm_subnet.spoke1_apps.id
  network_security_group_id = azurerm_network_security_group.spoke1_prod.id
}

# =====================================================================
# 2. NETWORK SECURITY GROUP: SPOKE 2 (TEST)
# =====================================================================
resource "azurerm_network_security_group" "spoke2_test" {
  name                = "nsg-spoke2-test"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Rule 120: SSH toestaan UITSLUITEND vanaf het Management Subnet
  security_rule {
    name                       = "Allow-SSH-From-MgmtSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "*"
  }

  # Rule 110: De gecontroleerde uitzondering voor Pings vanaf Spoke 1 Prod
  security_rule {
    name                       = "Allow-Ping-From-Firewall"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.0.0/16" # Bron: Spoke 1 Prod
    destination_address_prefix = "10.2.0.0/16" # Doel: Spoke 2 Test zelf
  }

  # Rule 130: Harde blokkade voor AL het andere verkeer uit Spoke 1 Prod
  security_rule {
    name                       = "Deny-Spoke1-Prod-Traffic"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
  }
}

# Koppel de NSG aan het subnet van Spoke 2
resource "azurerm_subnet_network_security_group_association" "spoke2_assoc" {
  subnet_id                 = azurerm_subnet.spoke2_apps.id
  network_security_group_id = azurerm_network_security_group.spoke2_test.id
}
