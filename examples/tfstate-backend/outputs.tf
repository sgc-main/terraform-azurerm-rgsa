output "resource_group_name" {
  description = "Name of the created resource group"
  value       = module.tfstate_storage.resource_group_name
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = module.tfstate_storage.storage_account_name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.tfstate_storage.storage_account_id
}

output "container_name" {
  description = "Name of the Terraform state container"
  value       = "tfstate"
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = module.tfstate_storage.primary_blob_endpoint
}

output "secondary_blob_endpoint" {
  description = "Secondary blob endpoint URL for disaster recovery"
  value       = module.tfstate_storage.secondary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string (sensitive)"
  value       = module.tfstate_storage.primary_connection_string
  sensitive   = true
}

output "backend_config" {
  description = "Terraform backend configuration snippet"
  value = <<-EOT
    # Add this to your Terraform configuration:
    
    terraform {
      backend "azurerm" {
        resource_group_name  = "${module.tfstate_storage.resource_group_name}"
        storage_account_name = "${module.tfstate_storage.storage_account_name}"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
      }
    }
    
    # Authentication methods:
    # 1. Azure CLI: az login
    # 2. Service Principal: Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
    # 3. Managed Identity: Automatically used when running from Azure resources
  EOT
}
