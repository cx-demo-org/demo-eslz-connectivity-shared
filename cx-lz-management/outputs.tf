output "management_group_resource_ids" {
  description = "Management group resource IDs created by the ALZ module."
  value       = try(module.alz.management_group_resource_ids, null)
}
