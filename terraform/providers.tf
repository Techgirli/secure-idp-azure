terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "idp-tfstate-rg"
    storage_account_name = "idptfstate001"
    container_name       = "tfstate"
    key                  = "secure-idp.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_protection_enabled = false
    }
  }
}

provider "azuread" {}   