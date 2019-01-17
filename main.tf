terraform {
  required_version = "~>0.11.8"

  backend "azurerm" {}
}

variable "AZURERM_SUBSCRIPTION_ID" {}
variable "AZURERM_CLIENT_ID" {}
variable "AZURERM_CLIENT_SECRET" {}
variable "AZURERM_TENANT_ID" {}

provider "azurerm" {
  version         = "~> 1.15"
  subscription_id = "${var.AZURERM_SUBSCRIPTION_ID}"
  client_id       = "${var.AZURERM_CLIENT_ID}"
  client_secret   = "${var.AZURERM_CLIENT_SECRET}"
  tenant_id       = "${var.AZURERM_TENANT_ID}"
}

resource "azurerm_resource_group" "testrg" {
  count    = "1"
  name     = "testrg"
  location = "westeurope"

  tags {
    provisioned_by = "terraform"
  }
}