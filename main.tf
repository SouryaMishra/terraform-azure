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

resource "azurerm_network_interface" "my-nic" {
  name                = "myNIC"
  resource_group_name = azurerm_resource_group.my-rg.name
  location            = azurerm_resource_group.my-rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "my-linux-vm" {
  name                  = "myLinuxVM"
  resource_group_name   = azurerm_resource_group.my-rg.name
  location              = azurerm_resource_group.my-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.my-nic.id]

  custom_data = filebase64("customdata.tpl") // VM needs to br re-deployed for custom_data to be read

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # provisioner does not get picked up by state, so vm must be replaced
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/azure_key" // private ssh key
    })
    interpreter = var.host_os == "windows" ? [
      "Powershell", "-Command"
    ] : ["bash", "-c"]
  }

  tags = {
    environment = "dev"
  }
}



data "azurerm_public_ip" "my-ip-data" {
  name                = azurerm_public_ip.my-ip.name
  resource_group_name = azurerm_resource_group.my-rg.name
}
moved {
  from = azurerm_resource_group.sm-rg
  to   = azurerm_resource_group.my-rg
}