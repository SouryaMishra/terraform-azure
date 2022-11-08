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

resource "azurerm_virtual_network" "my-vn" {
  name                = "myNetwork"
  resource_group_name = azurerm_resource_group.my-rg.name
  location            = azurerm_resource_group.my-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "my-subnet" {
  name                 = "mySubnet-1"
  resource_group_name  = azurerm_resource_group.my-rg.name
  virtual_network_name = azurerm_virtual_network.my-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

moved {
  from = azurerm_resource_group.sm-rg
  to   = azurerm_resource_group.my-rg
}