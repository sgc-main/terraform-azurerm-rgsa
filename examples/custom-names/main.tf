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
# Custom Named Storage Account with Full Configuration
# ==============================================================================
# This example demonstrates:
# - Name override variables for custom naming
# - Complete storage services (containers, file shares, tables, queues)
# - Advanced security features (managed identity, network rules)
# - Azure Files AD authentication
# - Lifecycle management policies
# - Static website hosting
# ==============================================================================

module "custom_storage" {
  source = "../../"

  # Location
  location = var.location

  # Custom Name Overrides (bypasses deterministic naming)
  storage_account_name_override = var.storage_account_name
  resource_group_name_override   = var.resource_group_name

  # Note: sa_prefix, subscription_shortcode, environment are optional when using overrides
  
  # Create new resource group
  create_resource_group = true

  # Storage Account Configuration
  account_kind       = "StorageV2"
  account_tier       = "Standard"
  replication_type   = "GRS"  # Geo-redundant storage
  min_tls_version    = "TLS1_2"
  is_hns_enabled     = true   # Enable Data Lake Gen2
  nfsv3_enabled      = false
  sftp_enabled       = true   # Enable SFTP (requires HNS)
  local_user_enabled = true

  # Large File Share Support
  large_file_share_enabled = true

  # Security Configuration
  public_network_access_enabled = true  # Accessible from internet (adjust as needed)
  shared_access_key_enabled     = true
  allowed_copy_scope            = "AAD"
  dns_endpoint_type             = "Standard"

  # Managed Identity
  managed_identity_type = "SystemAssigned"

  # Encryption
  infrastructure_encryption_enabled = true
  queue_encryption_key_type         = "Service"
  table_encryption_key_type         = "Service"

  # Blob Properties
  versioning_enabled                    = true
  change_feed_enabled                   = true
  change_feed_retention_in_days         = 7
  last_access_time_enabled              = true
  blob_soft_delete_retention_days       = 14
  container_soft_delete_retention_days  = 14
  permanent_delete_enabled              = false

  # Blob Containers
  containers = {
    data = {
      container_access_type = "private"
      metadata = {
        purpose = "application-data"
        tier    = "hot"
      }
    }
    backups = {
      container_access_type = "private"
      metadata = {
        purpose = "backup-storage"
        tier    = "cool"
      }
    }
    public = {
      container_access_type = "blob"
      metadata = {
        purpose = "public-assets"
      }
    }
  }

  # File Shares (SMB)
  file_shares = {
    documents = {
      quota = 100  # GB
      metadata = {
        department = "engineering"
        project    = "shared-docs"
      }
      acl = [
        {
          id          = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"
          access_policy = {
            permissions = "rwdl"
            start       = "2024-01-01T00:00:00Z"
            expiry      = "2025-12-31T23:59:59Z"
          }
        }
      ]
    }
    apps = {
      quota = 50
      enabled_protocol = "SMB"
      metadata = {
        purpose = "application-storage"
      }
    }
  }

  # Tables (NoSQL)
  tables = {
    logs = {
      acl = [
        {
          id          = "log-policy"
          access_policy = {
            permissions = "raud"
            start       = "2024-01-01T00:00:00Z"
            expiry      = "2025-12-31T23:59:59Z"
          }
        }
      ]
    }
    metrics = {}
  }

  # Queues
  queues = {
    tasks = {
      metadata = {
        purpose = "async-processing"
      }
    }
    notifications = {
      metadata = {
        purpose = "event-notifications"
      }
    }
  }

  # Network Rules
  network_rules = {
    default_action             = "Allow"  # Change to "Deny" for production with VNet access
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    ip_rules                   = []  # Add allowed IP ranges
    virtual_network_subnet_ids = []  # Add allowed subnet IDs
  }

  # Lifecycle Management Policy
  management_policy = {
    rules = [
      {
        name    = "tierOldData"
        enabled = true
        filters = {
          prefix_match = ["data/"]
          blob_types   = ["blockBlob"]
        }
        actions = {
          base_blob = {
            tier_to_cool_after_days_since_modification_greater_than    = 30
            tier_to_archive_after_days_since_modification_greater_than = 90
            delete_after_days_since_modification_greater_than          = 365
          }
          snapshot = {
            delete_after_days_since_creation_greater_than = 30
          }
        }
      },
      {
        name    = "deleteOldBackups"
        enabled = true
        filters = {
          prefix_match = ["backups/"]
          blob_types   = ["blockBlob"]
        }
        actions = {
          base_blob = {
            delete_after_days_since_modification_greater_than = 180
          }
        }
      }
    ]
  }

  # Azure Files Authentication (Optional - uncomment and configure)
  # azure_files_authentication = {
  #   directory_type = "AADDS"  # or "AD" or "AADKERB"
  #   active_directory = {
  #     domain_name         = "example.com"
  #     domain_guid         = "12345678-1234-1234-1234-123456789012"
  #     domain_sid          = "S-1-5-21-1234567890-1234567890-1234567890"
  #     storage_sid         = "S-1-5-21-1234567890-1234567890-1234567890-1234"
  #     forest_name         = "example.com"
  #     netbios_domain_name = "EXAMPLE"
  #   }
  # }

  # Static Website (Optional)
  static_website = {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  # Share Properties (SMB settings)
  share_properties = {
    cors_rule = {
      allowed_origins    = ["https://example.com"]
      allowed_methods    = ["GET", "HEAD", "POST"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
    retention_policy = {
      days = 7
    }
    smb = {
      versions                        = ["SMB3.0", "SMB3.1.1"]
      authentication_types            = ["Kerberos"]
      kerberos_ticket_encryption_type = ["AES-256"]
      channel_encryption_type         = ["AES-128-GCM", "AES-256-GCM"]
      multichannel_enabled            = true
    }
  }

  # Queue Properties
  queue_properties = {
    cors_rule = {
      allowed_origins    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
    logging = {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
    minute_metrics = {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 7
    }
    hour_metrics = {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 7
    }
  }

  # Routing Preference
  routing = {
    publish_internet_endpoints  = true
    publish_microsoft_endpoints = false
    choice                      = "MicrosoftRouting"
  }

  # SAS Policy
  sas_policy = {
    expiration_period = "90.00:00:00"  # 90 days
    expiration_action = "Log"
  }

  # Management Locks
  lock_resource_group  = true
  lock_storage_account = true

  # Tags
  tags = {
    Environment  = "Production"
    Application  = "CustomApp"
    ManagedBy    = "Terraform"
    CostCenter   = "Engineering"
    Owner        = "Platform Team"
    Compliance   = "SOC2"
    DataClass    = "Confidential"
  }
}
