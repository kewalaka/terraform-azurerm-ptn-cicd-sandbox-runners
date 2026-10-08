terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azapi_resource" "rg" {
  location = "newzealandnorth"
  name     = "rg-sbxrunners-test-${random_string.suffix.result}"
  type     = "Microsoft.Resources/resourceGroups@2024-11-01"
}

output "name" {
  value = "sbxg-test-${random_string.suffix.result}"
}

output "resource_group_id" {
  value = azapi_resource.rg.id
}
