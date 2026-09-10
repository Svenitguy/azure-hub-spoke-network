# =====================================================================
# 1. PRIVATE DNS ZONE
# =====================================================================
resource "azurerm_private_dns_zone" "securehub" {
  name                = "securehub.local"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# =====================================================================
# 2. VIRTUAL NETWORK LINKS (Met Auto-Registration voor de Spokes)
# =====================================================================

# Link naar Hub VNet (Geen auto-registration nodig)
resource "azurerm_private_dns_zone_virtual_network_link" "hub_link" {
  name                  = "link-hub-prod"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.securehub.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link naar Spoke 1 VNet (Met Auto-Registration)
resource "azurerm_private_dns_zone_virtual_network_link" "spoke1_link" {
  name                  = "link-spoke1-prod"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.securehub.name
  virtual_network_id    = azurerm_virtual_network.spoke1.id
  registration_enabled  = true
  tags                  = var.tags
}

# Link naar Spoke 2 VNet (Met Auto-Registration)
resource "azurerm_private_dns_zone_virtual_network_link" "spoke2_link" {
  name                  = "link-spoke2-test"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.securehub.name
  virtual_network_id    = azurerm_virtual_network.spoke2.id
  registration_enabled  = true
  tags                  = var.tags
}
