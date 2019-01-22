terraform {
  required_version = "~> 0.11.10"

  backend "azurerm" {}
}

provider "azurerm" {
  version = "~> 1.21"
}

resource "azurerm_resource_group" "testrg" {
  name     = "testrg"
  location = "westeurope"
}
