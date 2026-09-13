terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-phoenix-tfstate"
    storage_account_name = "stphoenixtfstate25814"
    container_name        = "tfstate"
    key                    = "phoenix-capstone.tfstate"
  }
}