terraform {
  required_version = "~>0.11.10"

  backend "azurerm" {}
}

variable "AZURERM_SUBSCRIPTION_ID" {}
variable "AZURERM_CLIENT_ID" {}
variable "AZURERM_CLIENT_SECRET" {}
variable "AZURERM_TENANT_ID" {}

provider "azurerm" {
  version         = "~> 1.21"
  subscription_id = "${var.AZURERM_SUBSCRIPTION_ID}"
  client_id       = "${var.AZURERM_CLIENT_ID}"
  client_secret   = "${var.AZURERM_CLIENT_SECRET}"
  tenant_id       = "${var.AZURERM_TENANT_ID}"
}