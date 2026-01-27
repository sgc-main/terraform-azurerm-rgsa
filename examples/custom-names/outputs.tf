output "resource_group_name" {
  description = "Name of the created resource group"
  value       = module.custom_storage.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.custom_storage.resource_group_id
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = module.custom_storage.storage_account_name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.custom_storage.storage_account_id
}

output "storage_account_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = module.custom_storage.storage_account_principal_id
}

# Endpoints
output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = module.custom_storage.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file share endpoint URL"
  value       = module.custom_storage.primary_file_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint URL"
  value       = module.custom_storage.primary_table_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint URL"
  value       = module.custom_storage.primary_queue_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake Storage Gen2 endpoint URL"
  value       = module.custom_storage.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "Primary static website endpoint URL"
  value       = module.custom_storage.primary_web_endpoint
}

# Storage Services
output "containers" {
  description = "Map of all created blob containers"
  value       = module.custom_storage.containers
}

output "container_names" {
  description = "List of all container names"
  value       = module.custom_storage.container_names
}

output "file_shares" {
  description = "Map of all created file shares"
  value       = module.custom_storage.file_shares
}

output "tables" {
  description = "Map of all created tables"
  value       = module.custom_storage.tables
}

output "queues" {
  description = "Map of all created queues"
  value       = module.custom_storage.queues
}

# Sensitive Outputs
output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = module.custom_storage.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the storage account"
  value       = module.custom_storage.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = module.custom_storage.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string for the storage account"
  value       = module.custom_storage.secondary_connection_string
  sensitive   = true
}

# Service-specific connection examples
output "file_share_connection_example" {
  description = "Example command to mount file share"
  value = <<-EOT
    # Mount Azure File Share on Linux
    sudo mount -t cifs //${module.custom_storage.storage_account_name}.file.core.windows.net/documents /mnt/documents \
      -o vers=3.0,username=${module.custom_storage.storage_account_name},password=<access-key>,dir_mode=0777,file_mode=0777,serverino
    
    # Or on Windows
    net use Z: \\\\${module.custom_storage.storage_account_name}.file.core.windows.net\\documents /user:${module.custom_storage.storage_account_name} <access-key>
  EOT
}

output "static_website_url" {
  description = "Static website URL (if enabled)"
  value       = module.custom_storage.primary_web_endpoint
}

output "lifecycle_policy_id" {
  description = "ID of the lifecycle management policy"
  value       = module.custom_storage.management_policy_id
}
