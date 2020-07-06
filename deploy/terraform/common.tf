terraform {
    backend "azurerm" {}
}

provider "azurerm" {
  version = "~> 2.16.0"
  features {}
}

provider "null" {
  version = "~> 2.1"
}

data "azurerm_client_config" "current" {}

# Learn our public IP address
data "http" "icanhazip" {
   url = "http://ipv4.icanhazip.com"
}

# Resource group for resources
resource "azurerm_resource_group" "rg" {
  name     = "${var.base_name}-${var.environment}-rg"
  location = var.location
}
