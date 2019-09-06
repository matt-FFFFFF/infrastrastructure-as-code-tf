terraform {
  required_version = "=0.12.8"

  backend "azurerm" {}
}


provider "azurerm" {
  version = "=1.33.1"
}

resource "azurerm_resource_group" "rg" {
  name     = "testrg"
  location = "westeurope"
}

// DO NOT ADD MORE INTO THIS FILE
