mock_provider "azapi" {}
mock_provider "modtm" {}

override_resource {
  target = azapi_resource.sandbox_group
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.App/sandboxGroups/sbxg-test"
    output = {
      properties = {
        managementEndpoint = "https://management.westus2.azuredevcompute.io"
      }
    }
  }
}

variables {
  location         = "westus2"
  name             = "sbxg-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  enable_telemetry = false
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.sandbox_group.type == "Microsoft.App/sandboxGroups@2026-02-01-preview"
    error_message = "The module must deploy a sandbox group."
  }

  assert {
    condition     = length(azapi_resource.vnet_connection) == 0 && length(azapi_resource.lock) == 0 && length(azapi_resource.data_plane_operator) == 0
    error_message = "Optional resources must not be created by default."
  }

  assert {
    condition     = output.management_endpoint == "https://management.westus2.azuredevcompute.io"
    error_message = "The management endpoint output must come from the sandbox group."
  }
}

run "all_features" {
  command = apply

  variables {
    max_sandbox_count = 5
    sandbox_defaults = {
      cpu    = "1"
      memory = "2Gi"
    }
    managed_identities = {
      system_assigned            = true
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"]
    }
    vnet_connection = {
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
    }
    data_plane_operators = {
      controller = { principal_id = "11111111-1111-1111-1111-111111111111" }
    }
    lock = { kind = "CanNotDelete" }
  }

  assert {
    condition     = azapi_resource.sandbox_group.identity[0].type == "SystemAssigned, UserAssigned"
    error_message = "Both identity types must be enabled."
  }

  assert {
    condition     = azapi_resource.sandbox_group.body.properties.defaultCpu == "1" && azapi_resource.sandbox_group.body.properties.maxSandboxCount == 5
    error_message = "Sandbox defaults and limits must be passed to the sandbox group."
  }

  assert {
    condition     = length(azapi_resource.vnet_connection) == 1 && length(azapi_resource.lock) == 1 && length(azapi_resource.data_plane_operator) == 1
    error_message = "The VNet connection, lock and data plane operator role assignment must be created."
  }

  assert {
    condition     = endswith(azapi_resource.data_plane_operator["controller"].body.properties.roleDefinitionId, "c24cf47c-5077-412d-a19c-45202126392c")
    error_message = "Operators must receive the Container Apps SandboxGroup Data Owner role."
  }
}

run "invalid_name" {
  command = plan

  variables {
    name = "-bad-name"
  }

  expect_failures = [var.name]
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
}

