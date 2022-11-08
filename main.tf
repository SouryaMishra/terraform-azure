terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my-rg" {
  name     = "myResourceGroup"
  location = "South India"

  tags = {
    environment = "dev"
  }
}

moved {
  from = azurerm_resource_group.sm-rg
  to = azurerm_resource_group.my-rg
}