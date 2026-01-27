# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group (created or existing)."
  value       = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
}

output "resource_group_id" {
  description = "ID of the resource group (created or existing)."
  value       = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
}

output "resource_group_location" {
  description = "Location of the resource group."
  value       = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Deterministic storage account name for Terraform state."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "Storage account resource ID."
  value       = azurerm_storage_account.this.id
}

output "storage_account_tier" {
  description = "Storage account tier."
  value       = azurerm_storage_account.this.account_tier
}

output "storage_account_kind" {
  description = "Storage account kind."
  value       = azurerm_storage_account.this.account_kind
}

output "storage_account_replication_type" {
  description = "Storage account replication type."
  value       = azurerm_storage_account.this.account_replication_type
}

output "storage_account_primary_location" {
  description = "Primary location of the storage account."
  value       = azurerm_storage_account.this.primary_location
}

output "storage_account_secondary_location" {
  description = "Secondary location of the storage account (for geo-redundant replication)."
  value       = azurerm_storage_account.this.secondary_location
}

# Container Outputs
output "containers" {
  description = "Map of all created blob containers with their details."
  value = {
    for k, v in azurerm_storage_container.this : k => {
      id                    = v.id
      name                  = v.name
      resource_manager_id   = v.resource_manager_id
      has_immutability_policy = v.has_immutability_policy
      has_legal_hold        = v.has_legal_hold
      metadata              = v.metadata
    }
  }
}

output "container_names" {
  description = "List of all container names."
  value       = keys(azurerm_storage_container.this)
}

output "container_ids" {
  description = "Map of container names to their resource IDs."
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}

# File Share Outputs
output "file_shares" {
  description = "Map of all created file shares with their details."
  value = {
    for k, v in azurerm_storage_share.this : k => {
      id                   = v.id
      name                 = v.name
      resource_manager_id  = v.resource_manager_id
      quota                = v.quota
      url                  = v.url
      metadata             = v.metadata
    }
  }
}

output "file_share_names" {
  description = "List of all file share names."
  value       = keys(azurerm_storage_share.this)
}

output "file_share_ids" {
  description = "Map of file share names to their resource IDs."
  value       = { for k, v in azurerm_storage_share.this : k => v.id }
}

# Table Outputs
output "tables" {
  description = "Map of all created storage tables with their details."
  value = {
    for k, v in azurerm_storage_table.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "table_names" {
  description = "List of all storage table names."
  value       = keys(azurerm_storage_table.this)
}

output "table_ids" {
  description = "Map of table names to their resource IDs."
  value       = { for k, v in azurerm_storage_table.this : k => v.id }
}

# Queue Outputs
output "queues" {
  description = "Map of all created storage queues with their details."
  value = {
    for k, v in azurerm_storage_queue.this : k => {
      id                  = v.id
      name                = v.name
      resource_manager_id = v.resource_manager_id
      metadata            = v.metadata
    }
  }
}

output "queue_names" {
  description = "List of all storage queue names."
  value       = keys(azurerm_storage_queue.this)
}

output "queue_ids" {
  description = "Map of queue names to their resource IDs."
  value       = { for k, v in azurerm_storage_queue.this : k => v.id }
}

# Management Policy Output
output "management_policy_id" {
  description = "ID of the storage account lifecycle management policy."
  value       = try(azurerm_storage_management_policy.this["enabled"].id, null)
}

# Blob Endpoints
output "primary_blob_endpoint" {
  description = "Primary blob endpoint for the storage account."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "secondary_blob_endpoint" {
  description = "Secondary blob endpoint (only meaningful for RA-GRS/RA-GZRS; read-only unless a failover occurs)."
  value       = azurerm_storage_account.this.secondary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host (hostname only, no protocol)."
  value       = azurerm_storage_account.this.primary_blob_host
}

output "secondary_blob_host" {
  description = "Secondary blob host (hostname only, no protocol)."
  value       = azurerm_storage_account.this.secondary_blob_host
}

# Additional Service Endpoints
output "primary_queue_endpoint" {
  description = "Primary queue endpoint for the storage account."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint for the storage account."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint for the storage account."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint for the storage account (Data Lake Gen2)."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "Primary web endpoint for static website hosting."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

# Identity Outputs
output "storage_account_principal_id" {
  description = "Principal ID of the storage account's system-assigned managed identity."
  value       = try(azurerm_storage_account.this.identity[0].principal_id, null)
}

output "storage_account_tenant_id" {
  description = "Tenant ID of the storage account's system-assigned managed identity."
  value       = try(azurerm_storage_account.this.identity[0].tenant_id, null)
}

# Connection Strings (marked as sensitive)
output "primary_connection_string" {
  description = "Primary connection string for the storage account."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string for the storage account."
  value       = azurerm_storage_account.this.secondary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "Primary access key for the storage account."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the storage account."
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}