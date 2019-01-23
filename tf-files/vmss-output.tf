output "jumpbox_public_ip" {
   value = "${azurerm_public_ip.jumpbox.fqdn}"
}

output "vmss_public_ip" {
   value = "${azurerm_public_ip.vmss.fqdn}"
}