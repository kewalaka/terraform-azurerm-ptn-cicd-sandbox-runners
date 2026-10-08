terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.13"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.4"
    }
  }
}

