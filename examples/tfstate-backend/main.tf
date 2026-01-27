terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

# ==============================================================================
# Terraform Remote State Storage Account
# ==============================================================================
# This example creates a dedicated storage account for Terraform state files
# with enterprise-grade security and disaster recovery capabilities.
# ==============================================================================

module "tfstate_storage" {
  source = "../../"

  # Location
  location = var.location

  # Deterministic Naming
  sa_prefix              = var.sa_prefix
  subscription_shortcode = var.subscription_shortcode
  environment            = var.environment
  rg_suffix              = "tfstate"

  # Create new resource group
  create_resource_group = true

  # Storage Account Configuration
  account_kind       = "StorageV2"
  account_tier       = "Standard"
  replication_type   = "RAGRS"  # Geo-redundant with read access to secondary region
  min_tls_version    = "TLS1_2"
  is_hns_enabled     = false
  nfsv3_enabled      = false
  sftp_enabled       = false
  local_user_enabled = true

  # Security Best Practices for Remote State
  public_network_access_enabled = false  # Use private endpoints only
  shared_access_key_enabled     = true   # Required for Terraform backend
  allowed_copy_scope            = "AAD"  # Restrict copy operations to AAD auth

  # Blob Properties for State Protection
  versioning_enabled                    = true   # Track all state changes
  change_feed_enabled                   = false
  last_access_time_enabled              = false
  blob_soft_delete_retention_days       = 30     # Extended recovery period
  container_soft_delete_retention_days  = 30     # Extended recovery period
  permanent_delete_enabled              = false  # Prevent permanent deletion during retention

  # Infrastructure Encryption (Double Encryption)
  infrastructure_encryption_enabled = true

  # Blob Container for Terraform State
  containers = {
    tfstate = {
      container_access_type = "private"
      metadata              = {
        purpose     = "terraform-remote-state"
        environment = var.environment
        managed_by  = "terraform"
      }
    }
  }

  # Management Locks (Prevent Accidental Deletion)
  lock_resource_group   = true
  lock_storage_account  = true

  # Network Rules (Customize for your environment)
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = []  # Add your IP addresses here
    virtual_network_subnet_ids = []  # Add subnet IDs for private access
    
    # Private Link Access (optional)
    # private_link_access = [
    #   {
    #     endpoint_resource_id = "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateEndpoints/<pe-name>"
    #     endpoint_tenant_id   = "<tenant-id>"
    #   }
    # ]
  }

  # Lifecycle Management (Optional - Keep state files lean)
  management_policy = {
    rules = [
      {
        name    = "deleteOldVersions"
        enabled = true
        filters = {
          prefix_match = ["tfstate/"]
          blob_types   = ["blockBlob"]
        }
        actions = {
          version = {
            delete_after_days_since_creation = 90  # Keep 90 days of versions
          }
        }
      }
    ]
  }

  # Tags
  tags = {
    Environment  = var.environment
    Purpose      = "Terraform Remote State"
    ManagedBy    = "Terraform"
    CostCenter   = var.cost_center
    Owner        = var.owner
    Compliance   = "Required"
    DR           = "Enabled"
  }
}
