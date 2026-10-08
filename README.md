# terraform-azurerm-ptn-cicd-sandbox-runners

Infrastructure for CI/CD runners on [Azure Container Apps (ACA) Sandboxes](https://sandboxes.azure.com/docs/sandboxes/): fast, isolated, ephemeral Linux VMs.

An AzAPI pattern module (no `azurerm`), inspired by [`avm-ptn-cicd-agents-and-runners`](https://github.com/Azure/terraform-azurerm-avm-ptn-cicd-agents-and-runners).

> **Preview.** ACA Sandboxes uses `Microsoft.App/sandboxGroups@2026-02-01-preview`.

## What it deploys

| Resource | Purpose |
|---|---|
| `Microsoft.App/sandboxGroups` | The runner pool: security/config boundary with sandbox defaults (CPU, memory, disk, timeout) and a max sandbox count. Optional system/user-assigned identity. |
| `Microsoft.App/sandboxGroups/vnetConnections` | Optional private networking via a subnet delegated to `Microsoft.App/environments`. |
| `Microsoft.Authorization/roleAssignments` | `Container Apps SandboxGroup Data Owner` for the principals that drive the data plane. |
| `Microsoft.Authorization/locks` | Optional lock. |

## Sandboxes are not ARM resources

Individual sandboxes (the runners) live on the regional data plane (`management_endpoint` output), so Terraform/AzAPI cannot create them. Your runner controller (CLI, SDK or REST) starts one ephemeral sandbox per job using an identity passed in `data_plane_operators`. This module provides the group, network, identity and access it needs.

## Usage

```hcl
module "sandbox_runners" {
  source = "<this module>"

  location  = "newzealandnorth"
  name      = "sbxg-runners"
  parent_id = azapi_resource.rg.id

  data_plane_operators = {
    controller = { principal_id = var.controller_object_id, principal_type = "ServicePrincipal" }
  }
  sandbox_defaults  = { cpu = "1", memory = "2Gi", disk = "20Gi", timeout_seconds = 3600 }
  max_sandbox_count = 20
}
```

See [`examples/default`](./examples/default) for a full deployable example (resource group, VNet, sandbox group).

## Inputs

| Name | Description | Default |
|---|---|---|
| `location` | Region (must support ACA Sandboxes). | required |
| `name` | Sandbox group name (1-32 chars: letters, digits, hyphens). | required |
| `parent_id` | Resource group resource ID. | required |
| `data_plane_operators` | Map of principals granted the Data Owner role. | `{}` |
| `enable_telemetry` | AVM telemetry. | `true` |
| `lock` | `{ kind, name }` resource lock. | `null` |
| `managed_identities` | `{ system_assigned, user_assigned_resource_ids }`. | `{}` |
| `max_sandbox_count` | Max sandboxes in the group. | service default |
| `sandbox_defaults` | `{ cpu, memory, disk, timeout_seconds }` defaults. | service defaults |
| `vnet_connection` | `{ subnet_id }`; immutable once set. | `null` |
| `tags` | Tags. | `null` |

## Outputs

`resource_id`, `name`, `management_endpoint`, `system_assigned_mi_principal_id`.

## Testing

```shell
terraform test -test-directory=tests/unit          # mocked, no Azure needed
terraform test -test-directory=tests/integration   # deploys to Azure
```

## Telemetry

See <https://aka.ms/avm/telemetryinfo>. Disable with `enable_telemetry = false`.
