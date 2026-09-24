# =====================================================================
# 1. ENTERPRISE SECURE STORAGE ACCOUNT (Trivy AZU-0012 Compliant)
# =====================================================================
resource "azurerm_storage_account" "secure_storage" {
  name                     = "sthubspokesharedsv001"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # ZERO TRUST STAP 1: Openbare netwerktoegang op platformniveau uitschakelen
  public_network_access_enabled = false

  # ZERO TRUST STAP 2 (FIX AZU-0012 & AZU-0010): Interne firewall-engine initialiseren op DENY met AzureServices bypass
  network_rules {
    default_action = "Deny"
    # AZURERM V4 & TRIVY FIX: Voeg "AzureServices" toe om Trusted Microsoft Services (zoals Azure Backup) toe te laten via de backbone
    bypass = ["Metrics", "Logging", "AzureServices"]
  }

  tags = var.tags
}

# NoSQL Blob Container voor ongestructureerde applicatiedata en logs
resource "azurerm_storage_container" "raw_data" {
  name                  = "raw-data"
  storage_account_id    = azurerm_storage_account.secure_storage.id
  container_access_type = "private"
}

# Gedeelde netwerkschijf (SMB) voor traditionele bestandsuitwisseling
resource "azurerm_storage_share" "shared_files" {
  name               = "shared-files"
  storage_account_id = azurerm_storage_account.secure_storage.id

  quota = 50 # 50 GB limiet om onverwachte cloudkosten te beheersen
}

# =====================================================================
# 2. PRIVATE ENDPOINT INTEGRATIE (Koppeling met Spoke 1)
# =====================================================================
resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-storage-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke1_apps.id # Landt veilig in je sn-spoke1-apps subnet

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.secure_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

# =====================================================================
# 3. PRIVATE LINK NAAMRESOLUTIE (DNS)
# =====================================================================
resource "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Koppel de Blob DNS-zone aan je centrale Hub VNet zodat naamresolutie werkt
resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_hub_link" {
  name                  = "link-blob-dns-to-hub"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

# Koppel de Blob DNS-zone ook aan Spoke 1 zodat je VM de storage kan vinden
resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_spoke1_link" {
  name                  = "link-blob-dns-to-spoke1"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_blob.name
  virtual_network_id    = azurerm_virtual_network.spoke1.id
  tags                  = var.tags
}

# Automatische A-Record registratie voor het private IP van je Storage Account
resource "azurerm_private_dns_a_record" "storage_dns_record" {
  name                = azurerm_storage_account.secure_storage.name
  zone_name           = azurerm_private_dns_zone.dns_blob.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_pe.private_service_connection[0].private_ip_address]
}
