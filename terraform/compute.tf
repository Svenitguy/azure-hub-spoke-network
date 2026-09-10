# =====================================================================
# 1. AZURE BASTION INFRASTRUCTUUR
# =====================================================================
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bst-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bst-hub-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# =====================================================================
# 2. VIRTUELE MACHINE: SPOKE 1 (PROD)
# =====================================================================
resource "azurerm_network_interface" "vm_spoke1_nic" {
  name                = "vm-spoke1-prod-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke1_apps.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_spoke1" {
  name                            = "vm-spoke1-prod"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "azureuser"
  admin_password                  = "JeVeiligWachtwoord2026!" # Wijzigen in productie!
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm_spoke1_nic.id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Goedkope HDD voor de lab-omgeving
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_spoke1" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm_spoke1.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = "1800" # 18:00 uur uitschakelen (FinOps)
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }
}

# =====================================================================
# 3. VIRTUELE MACHINE: SPOKE 2 (TEST)
# =====================================================================
resource "azurerm_network_interface" "vm_spoke2_nic" {
  name                = "vm-spoke2-test-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke2_apps.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_spoke2" {
  name                            = "vm-spoke2-test"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "azureuser"
  admin_password                  = "JeVeiligWachtwoord2026!" # Wijzigen in productie!
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm_spoke2_nic.id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_spoke2" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm_spoke2.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = "1800"
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }
}
