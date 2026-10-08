terraform {
  required_version = ">= 1.9, < 2.0"

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

provider "azapi" {}

variable "location" {
  type        = string
  default     = "newzealandnorth"
  description = "The Azure region to deploy into. Must support ACA Sandboxes."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable module telemetry."
}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azapi_resource" "rg" {
  location = var.location
  name     = "rg-sbxrunners-${random_string.suffix.result}"
  type     = "Microsoft.Resources/resourceGroups@2024-11-01"
}

# One subnet per sandbox group; the subnet must be delegated to Microsoft.App/environments.
resource "azapi_resource" "vnet" {
  location  = var.location
  name      = "vnet-sbxrunners"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = { addressPrefixes = ["10.0.0.0/16"] }
    }
  }
}

resource "azapi_resource" "subnet" {
  name      = "snet-sandboxes"
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.0.0.0/23"
      delegations = [{
        name       = "sandboxes"
        properties = { serviceName = "Microsoft.App/environments" }
      }]
    }
  }
}

module "sandbox_runners" {
  source = "../../"

  location  = var.location
  name      = "sbxg-runners-${random_string.suffix.result}"
  parent_id = azapi_resource.rg.id
  # The deploying principal can drive the sandbox data plane (e.g. to start runner sandboxes).
  data_plane_operators = {
    deployer = { principal_id = data.azapi_client_config.current.object_id }
  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
  max_sandbox_count = 5
  sandbox_defaults = {
    cpu             = "1"
    memory          = "2Gi"
    disk            = "20Gi"
    timeout_seconds = 3600
  }
  vnet_connection = {
    subnet_id = azapi_resource.subnet.id
  }
}

output "management_endpoint" {
  value = module.sandbox_runners.management_endpoint
}

output "resource_id" {
  value = module.sandbox_runners.resource_id
}

output "resource_group_id" {
  value = azapi_resource.rg.id
}

