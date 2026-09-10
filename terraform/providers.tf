terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Moderne 2026 azurerm provider v4x
    }
  }
}

provider "azurerm" {
  features {}
}
