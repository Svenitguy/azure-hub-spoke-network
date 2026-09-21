terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Moderne 2026 azurerm provider v4x
    }
    # DEVSECOPS INTEGRATIE: Voeg de TLS provider toe voor automatische sleutelgeneratie
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  # Dit is de cloud-backend voor je Terraform-geheugen
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesveniac"
    container_name       = "tfstate-hub-spoke"
    key                  = "hub-spoke.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# De TLS provider initialiseren (heeft geen extra instellingen nodig)
provider "tls" {}
