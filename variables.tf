variable "location" {
  type        = string
  description = "The Azure region for the sandbox group. Must be a region where ACA Sandboxes is available."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the sandbox group (1-32 characters: letters, digits and hyphens; cannot start with a hyphen or period)."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,31}$", var.name))
    error_message = "The name must be 1-32 characters: letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the resource group to deploy the sandbox group into."
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.parent_id))
    error_message = "parent_id must be a resource group resource ID."
  }
}

variable "data_plane_operators" {
  type = map(object({
    principal_id   = string
    principal_type = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
Principals granted the `Container Apps SandboxGroup Data Owner` role on the sandbox group. The role is required to call the
sandbox data plane (create sandboxes, run commands, take snapshots), e.g. the identity of a CI runner controller.

- `principal_id` - The object ID of the user, group or service principal.
- `principal_type` - (Optional) `User`, `Group` or `ServicePrincipal`. Set it for newly created service principals to avoid Entra replication races.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for v in var.data_plane_operators : v.principal_type == null || contains(["User", "Group", "ServicePrincipal"], v.principal_type)])
    error_message = "principal_type must be one of User, Group or ServicePrincipal."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the resource lock on the sandbox group.

- `kind` - The lock level. Possible values are `CanNotDelete` and `ReadOnly`.
- `name` - (Optional) The name of the lock. Defaults to `lock-<name>`.
DESCRIPTION

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "lock.kind must be either `CanNotDelete` or `ReadOnly`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Managed identities of the sandbox group, used for registry pulls and gateway connections.

- `system_assigned` - (Optional) Enable the system-assigned identity.
- `user_assigned_resource_ids` - (Optional) Resource IDs of user-assigned identities to attach.
DESCRIPTION
  nullable    = false
}

variable "max_sandbox_count" {
  type        = number
  default     = null
  description = "The maximum number of sandboxes in the group. Defaults to the service default."

  validation {
    condition     = var.max_sandbox_count == null || var.max_sandbox_count >= 1
    error_message = "max_sandbox_count must be at least 1."
  }
}

variable "sandbox_defaults" {
  type = object({
    cpu             = optional(string)
    memory          = optional(string)
    disk            = optional(string)
    timeout_seconds = optional(number)
  })
  default     = {}
  description = <<DESCRIPTION
Defaults applied to sandboxes that don't specify their own. Unset values use the service defaults.

- `cpu` - vCPUs, e.g. `1`.
- `memory` - Memory, e.g. `2Gi`.
- `disk` - Disk size, e.g. `20Gi`.
- `timeout_seconds` - Sandbox lifetime before the platform tears it down.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to assign to the sandbox group."
}

variable "vnet_connection" {
  type = object({
    subnet_id = string
  })
  default     = null
  description = <<DESCRIPTION
Connects the sandbox group to a VNet, giving sandboxes private network access.

- `subnet_id` - The resource ID of a subnet delegated to `Microsoft.App/environments`. Immutable once set, so size it for peak sandbox concurrency.
DESCRIPTION
}

