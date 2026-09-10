# =====================================================================
# 1. ROUTE TABEL: SPOKE 1 (PROD) -> HUB
# =====================================================================
resource "azurerm_route_table" "spoke1_to_hub" {
  name                          = "rt-spoke1-to-hub-tf"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  # Route 1: Al het internetverkeer naar de Firewall
  route {
    name                   = "to-firewall-prod-default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.firewall.address_prefixes[0], 4) # Resulteert in 10.0.4.4
  }

  # Route 2: Verkeer naar Spoke 2 dwingen via de Firewall (Cruciaal voor de Ping!)
  route {
    name                   = "to-firewall-to-spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.firewall.address_prefixes[0], 4)
  }
}

# Koppel de Route Tabel aan het subnet van Spoke 1
resource "azurerm_subnet_route_table_association" "spoke1_route_assoc" {
  subnet_id      = azurerm_subnet.spoke1_apps.id
  route_table_id = azurerm_route_table.spoke1_to_hub.id
}


# =====================================================================
# 2. ROUTE TABEL: SPOKE 2 (TEST) -> HUB
# =====================================================================
resource "azurerm_route_table" "spoke2_to_hub" {
  name                          = "rt-spoke2-to-hub-tf"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  # Route 1: Al het internetverkeer naar de Firewall
  route {
    name                   = "to-firewall-test-default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.firewall.address_prefixes[0], 4)
  }

  # Route 2: Verkeer naar Spoke 1 dwingen via de Firewall
  route {
    name                   = "to-firewall-to-spoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.firewall.address_prefixes[0], 4)
  }
}

# Koppel de Route Tabel aan het subnet van Spoke 2
resource "azurerm_subnet_route_table_association" "spoke2_route_assoc" {
  subnet_id      = azurerm_subnet.spoke2_apps.id
  route_table_id = azurerm_route_table.spoke2_to_hub.id # Gewijzigd van spoke1 naar spoke2!
}
