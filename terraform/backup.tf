# =====================================================================
# 1. RECOVERY SERVICES VAULT (BCDR Kern)
# =====================================================================
resource "azurerm_recovery_services_vault" "vault" {
  name                = "rsv-secure-landingzone-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant" # FinOps: Voorkomt onnodige replicatiekosten

  tags = var.tags
}

# =====================================================================
# 2. FILE SHARE BACKUP POLICY & BESCHERMING
# =====================================================================

# Geautomatiseerd back-upbeleid (Dagelijkse back-up met 30 dagen retentie)
resource "azurerm_backup_policy_file_share" "fs_policy" {
  name                = "policy-daily-fileshare-backup"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  timezone            = "Romance Standard Time"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}

# Registreer de Storage Account binnen de Back-up Vault
resource "azurerm_backup_container_storage_account" "storage_container" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  storage_account_id  = azurerm_storage_account.secure_storage.id
}

# Activeer de daadwerkelijke back-upbescherming op je File Share
resource "azurerm_backup_protected_file_share" "share_backup" {
  resource_group_name       = azurerm_resource_group.rg.name
  recovery_vault_name       = azurerm_recovery_services_vault.vault.name
  source_storage_account_id = azurerm_storage_account.secure_storage.id
  source_file_share_name    = azurerm_storage_share.shared_files.name
  backup_policy_id          = azurerm_backup_policy_file_share.fs_policy.id

  depends_on = [azurerm_backup_container_storage_account.storage_container]
}

# =====================================================================
# 3. RANSOMWARE BESCHERMING (Immutable WORM Policy)
# =====================================================================
resource "azurerm_storage_container_immutability_policy" "ransomware_protection" {
  storage_container_id = azurerm_storage_container.raw_data.id

  # Aantal dagen dat data mathematisch beschermd is tegen overschrijven/wissen
  retention_period_in_days = 7

  # LAB BEST PRACTICE: Laat dit op false. Als je dit op true zet (Locked), 
  # kan de container NOOIT meer worden verwijderd, wat problemen geeft bij een 'terraform destroy'.
  protected_until_date_is_locked = false
}
