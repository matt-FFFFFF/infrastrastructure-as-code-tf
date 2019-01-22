terraform {
  required_version = "~>0.11.10"

  backend "azurerm" {}
}

provider "azurerm" {
  required_version = "~>1.21"
}

resource "azurerm_resource_group" "testrg" {
  count    = "1"
  name     = "testrg"
  location = "westeurope"

  tags {
    provisioned_by = "terraform"
  }
}

resource "azurerm_resource_group" "testrg2" {
  count    = "1"
  name     = "testrg2"
  location = "westeurope"

  tags {
    provisioned_by = "terraform"
  }
}