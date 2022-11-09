output "public_ip_address" {
    value =  "${azurerm_linux_virtual_machine.my-linux-vm.name}:${data.azurerm_public_ip.my-ip-data.ip_address}"
}