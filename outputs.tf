output "management_endpoint" {
  description = "The regional data plane endpoint used to create and manage sandboxes (sandboxes are not ARM resources)."
  value       = azapi_resource.sandbox_group.output.properties.managementEndpoint
}

output "name" {
  description = "The name of the sandbox group."
  value       = azapi_resource.sandbox_group.name
}

output "resource_id" {
  description = "The resource ID of the sandbox group."
  value       = azapi_resource.sandbox_group.id
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system-assigned managed identity, if enabled."
  value       = try(azapi_resource.sandbox_group.identity[0].principal_id, null)
}
