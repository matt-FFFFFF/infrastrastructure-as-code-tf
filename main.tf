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
  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

resource "azurerm_resource_group" "testrg" {
  count    = "1"
  name     = "testrg"
  location = "westeurope"

  tags {
    provisioned_by = "terraform"
  }
}