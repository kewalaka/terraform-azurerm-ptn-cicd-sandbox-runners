locals {
  api_version = "2026-07-01"

  # Built-in role that grants access to the sandbox data plane (create/exec/snapshot sandboxes).
  sandbox_data_owner_role_definition_id = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/c24cf47c-5077-412d-a19c-45202126392c"
  subscription_id                       = split("/", var.parent_id)[2]
  identity_type = join(", ", compact([
    var.managed_identities.system_assigned ? "SystemAssigned" : "",
    length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "",
  ]))
}

resource "azapi_resource" "sandbox_group" {
  location                  = var.location
  name                      = var.name
  parent_id                 = var.parent_id
  type                      = "Microsoft.App/sandboxGroups@${local.api_version}"
  ignore_null_property      = true
  response_export_values    = ["properties.managementEndpoint", "properties.provisioningState"]
  schema_validation_enabled = false
  tags                      = var.tags
  body = {
    properties = {
      defaultCpu            = var.sandbox_defaults.cpu
      defaultMemory         = var.sandbox_defaults.memory
      defaultDisk           = var.sandbox_defaults.disk
      defaultTimeoutSeconds = var.sandbox_defaults.timeout_seconds
      maxSandboxCount       = var.max_sandbox_count
    }
  }

  dynamic "identity" {
    for_each = local.identity_type == "" ? [] : [local.identity_type]

    content {
      type         = identity.value
      identity_ids = var.managed_identities.user_assigned_resource_ids
    }
  }
}

# The subnet must be delegated to Microsoft.App/environments and cannot be changed once set.
resource "azapi_resource" "vnet_connection" {
  count = var.vnet_connection == null ? 0 : 1

  location                  = var.location
  name                      = "default"
  parent_id                 = azapi_resource.sandbox_group.id
  type                      = "Microsoft.App/sandboxGroups/vnetConnections@${local.api_version}"
  ignore_casing             = true
  schema_validation_enabled = false
  body = {
    properties = {
      subnetId = var.vnet_connection.subnet_id
    }
  }
}

resource "azapi_resource" "data_plane_operator" {
  for_each = var.data_plane_operators

  name      = uuidv5("url", "${var.parent_id}/${var.name}/${each.key}")
  parent_id = azapi_resource.sandbox_group.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      roleDefinitionId = local.sandbox_data_owner_role_definition_id
      principalId      = each.value.principal_id
      principalType    = each.value.principal_type
    }
  }
  ignore_null_property = true
}

resource "azapi_resource" "lock" {
  count = var.lock == null ? 0 : 1

  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azapi_resource.sandbox_group.id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = "Deleting the sandbox group deletes every sandbox, snapshot and disk image inside it."
    }
  }
}


