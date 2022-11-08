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

resource "azurerm_network_security_group" "my-nsg" {
  name                = "myNetworkSecurityGroup"
  resource_group_name = azurerm_resource_group.my-rg.name
  location            = azurerm_resource_group.my-rg.location
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "my-dev-rule" {
  name                        = "myNetworkSecurityDevRule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*" // my public ip address can also be added
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.my-rg.name
  network_security_group_name = azurerm_network_security_group.my-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "my-sga" {
  subnet_id                 = azurerm_subnet.my-subnet.id
  network_security_group_id = azurerm_network_security_group.my-nsg.id
}

resource "azurerm_public_ip" "my-ip" {
  name                = "myIP-1"
  resource_group_name = azurerm_resource_group.my-rg.name
  location            = azurerm_resource_group.my-rg.location
  allocation_method   = "Dynamic"
  tags = {
    environment = "dev"
  }
}

moved {
  from = azurerm_resource_group.sm-rg
  to   = azurerm_resource_group.my-rg
}