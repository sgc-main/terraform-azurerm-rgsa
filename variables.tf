variable "location" {
  description = "Azure region for the tfstate resource group and storage account."
  type        = string
}

variable "storage_account_name_override" {
  description = "Override for storage account name. If provided, bypasses the deterministic naming convention. Must be globally unique, 3-24 characters, lowercase letters and numbers only."
  type        = string
  default     = null
  
  validation {
    condition     = var.storage_account_name_override == null || can(regex("^[a-z0-9]{3,24}$", var.storage_account_name_override))
    error_message = "storage_account_name_override must be 3-24 characters and contain only lowercase letters and numbers (a-z, 0-9)."
  }
}

variable "resource_group_name_override" {
  description = "Override for resource group name. If provided, bypasses the deterministic naming convention."
  type        = string
  default     = null
  
  validation {
    condition     = var.resource_group_name_override == null || (can(regex("^[a-zA-Z0-9._\\(\\)-]{1,90}$", var.resource_group_name_override)) && !can(regex("[._]$", var.resource_group_name_override)))
    error_message = "resource_group_name_override must be 1-90 characters, can contain alphanumerics, underscores, parentheses, hyphens, periods, and cannot end with a period."
  }
}

variable "sa_prefix" {
  description = "Prefix used in the deterministic storage account name. Must be lowercase alphanumeric. Not required if storage_account_name_override is provided."
  type        = string
  default     = "comtfstate"

  validation {
    condition     = var.sa_prefix == "" || can(regex("^[a-z0-9]+$", var.sa_prefix))
    error_message = "sa_prefix must be lowercase letters and numbers only (a-z, 0-9)."
  }
}

variable "subscription_shortcode" {
  description = "Unique short abbreviation of the subscription. Lowercase alphanumeric only. Not required if storage_account_name_override is provided."
  type        = string
  default     = ""

  validation {
    condition     = var.subscription_shortcode == "" || can(regex("^[a-z0-9]+$", var.subscription_shortcode))
    error_message = "subscription_shortcode must be lowercase letters and numbers only (a-z, 0-9)."
  }

  # Note: Total length validation (sa_prefix + subscription_shortcode + environment <= 24)
  # is performed in locals block since variable validations cannot reference other variables
}

variable "environment" {
  description = "3-letter environment code (e.g., dev, prd, stg). Not required if storage_account_name_override is provided."
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || can(regex("^[a-z0-9]{3}$", var.environment))
    error_message = "environment must be exactly 3 characters (lowercase letters/numbers), e.g. dev/prd/stg."
  }
}

variable rg_suffix {
  description = "Suffix to append to the resource group name."
  type        = string
  default     = "tfstate"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one."
  type        = bool
  default     = true
}

variable "existing_resource_group_name" {
  description = "Name of existing resource group to use when create_resource_group is false. If not provided, will use the generated resource_group_name."
  type        = string
  default     = null
}

variable "containers" {
  description = "Map of blob containers to create. Key is the container name. If not provided, defaults to creating a 'tfstate' container with private access."
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string))
  }))
  default = {
    tfstate = {
      container_access_type = "private"
    }
  }
  
  validation {
    condition     = alltrue([for k, v in var.containers : can(regex("^[a-z0-9-]{3,63}$", k))])
    error_message = "Container names must be 3–63 characters using lowercase letters, numbers, or dashes."
  }
  
  validation {
    condition     = alltrue([for k, v in var.containers : contains(["private", "blob", "container"], v.container_access_type)])
    error_message = "container_access_type must be one of: private, blob, container."
  }
}

variable "account_kind" {
  description = "The type of storage account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  default     = "StorageV2"
  type        = string

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "account_kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "account_tier" {
  description = "Storage account tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "Replication type for multi-region DR. Use RAGZRS (recommended) or RAGRS."
  type        = string
  default     = "RAGRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], upper(var.replication_type))
    error_message = "replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}


variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "Is Hierarchical Namespace enabled? To be used with Azure DataLake Gen 2"
}

variable "sftp_enabled" {
  type        = bool
  default     = false
  description = "Enable SFTP for the storage account"
}

variable cross_tenant_replication_enabled {
  description = "Enable cross-tenant replication for the storage account. Only applicable for RA-GRS/RA-GZRS accounts."
  type        = bool
  default     = false
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  default     = "TLS1_2"
  type        = string
}

variable allow_nested_items_to_be_public {
  description = "Allow nested items within containers to be public even if the container is private."
  type        = bool
  default     = false
}

variable "managed_identity_type" {
  description = "The type of Managed Identity which should be assigned to the storage account. Possible values are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`"
  default     = null
  type        = string
}

variable public_network_access_enabled {
  description = "Enable public network access to the storage account."
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared key authentication. Keep true unless enforcing RBAC-only backend access."
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Is versioning enabled? Default to `false`."
  default     = false
  type        = bool
}

variable "last_access_time_enabled" {
  description = "Is the last access time based tracking enabled? Default to `false`"
  default     = false
  type        = bool
}

variable "change_feed_enabled" {
  description = "Is the blob service properties for change feed events enabled?"
  default     = false
  type        = bool
}

variable "blob_soft_delete_retention_days" {
  description = "Blob soft delete retention in days."
  type        = number
  default     = 14
}

variable "container_soft_delete_retention_days" {
  description = "Container soft delete retention in days."
  type        = number
  default     = 14
}

variable "cors_rule" {
  description = "A map of CORS rules to add to the storage account"
  type = object({
    allowed_origins    = optional(list(string))
    allowed_methods    = optional(list(string))
    allowed_headers    = optional(list(string))
    exposed_headers    = optional(list(string))
    max_age_in_seconds = optional(number)
  })
  default = null
}

variable "network_rules" {
  description = "Network rules restricting access to the storage account. Either ip_rules or virtual_network_subnet_ids must be specified when using this."
  type = object({
    bypass                     = list(string)
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
  })
  default = null
}

variable "lock_resource_group" {
  description = "Apply CanNotDelete lock to the resource group."
  type        = bool
  default     = false
}

variable "lock_storage_account" {
  description = "Apply CanNotDelete lock to the storage account."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "managed_identity_ids" {
  description = "A list of User Assigned Managed Identity IDs to be assigned to the storage account. Required when managed_identity_type is UserAssigned or SystemAssigned, UserAssigned."
  type        = list(string)
  default     = null
}

variable "nfsv3_enabled" {
  description = "Enable NFSv3 protocol. Can only be true when account_tier is Standard and account_kind is StorageV2, or account_tier is Premium and account_kind is BlockBlobStorage. Additionally, is_hns_enabled must be true and account_replication_type must be LRS or RAGRS."
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain configuration for the storage account."
  type = object({
    name          = string
    use_subdomain = optional(bool)
  })
  default = null
}

variable "queue_properties" {
  description = "Queue service properties. Can only be configured when account_tier is Standard and account_kind is Storage or StorageV2."
  type = object({
    cors_rule = optional(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    }))
    logging = optional(object({
      delete                = bool
      read                  = bool
      write                 = bool
      version               = string
      retention_policy_days = optional(number)
    }))
    minute_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
    hour_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
  })
  default = null
}

variable "static_website" {
  description = "Static website configuration. Can only be set when account_kind is StorageV2 or BlockBlobStorage."
  type = object({
    index_document     = optional(string)
    error_404_document = optional(string)
  })
  default = null
}

variable "share_properties" {
  description = "File share service properties. Can only be configured when account_tier is Standard and account_kind is Storage or StorageV2, or when account_tier is Premium and account_kind is FileStorage."
  type = object({
    cors_rule = optional(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    }))
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      versions                        = optional(list(string))
      authentication_types            = optional(list(string))
      kerberos_ticket_encryption_type = optional(list(string))
      channel_encryption_type         = optional(list(string))
      multichannel_enabled            = optional(bool)
    }))
  })
  default = null
}

variable "large_file_share_enabled" {
  description = "Enable Large File Shares. Enabled by default when account_kind is FileStorage."
  type        = bool
  default     = false
}

variable "local_user_enabled" {
  description = "Enable Local User authentication."
  type        = bool
  default     = false
}

variable "azure_files_authentication" {
  description = "Azure Files authentication configuration. Required when using AD authentication."
  type = object({
    directory_type = string
    active_directory = optional(object({
      domain_name         = string
      domain_guid         = string
      domain_sid          = optional(string)
      storage_sid         = optional(string)
      forest_name         = optional(string)
      netbios_domain_name = optional(string)
    }))
    default_share_level_permission = optional(string)
  })
  default = null
  
  validation {
    condition     = var.azure_files_authentication == null || contains(["AADDS", "AD", "AADKERB"], try(var.azure_files_authentication.directory_type, ""))
    error_message = "directory_type must be one of: AADDS, AD, AADKERB."
  }
}

variable "routing" {
  description = "Network routing configuration for the storage account."
  type = object({
    publish_internet_endpoints  = optional(bool, false)
    publish_microsoft_endpoints = optional(bool, false)
    choice                      = optional(string, "MicrosoftRouting")
  })
  default = null
  
  validation {
    condition     = var.routing == null || contains(["InternetRouting", "MicrosoftRouting"], try(var.routing.choice, "MicrosoftRouting"))
    error_message = "routing.choice must be either InternetRouting or MicrosoftRouting."
  }
}

variable "queue_encryption_key_type" {
  description = "The encryption type of the queue service. Cannot be Account when account_kind is Storage."
  type        = string
  default     = "Service"
  
  validation {
    condition     = contains(["Service", "Account"], var.queue_encryption_key_type)
    error_message = "queue_encryption_key_type must be Service or Account."
  }
}

variable "table_encryption_key_type" {
  description = "The encryption type of the table service. Cannot be Account when account_kind is Storage."
  type        = string
  default     = "Service"
  
  validation {
    condition     = contains(["Service", "Account"], var.table_encryption_key_type)
    error_message = "table_encryption_key_type must be Service or Account."
  }
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption. Can only be true when account_kind is StorageV2 or when account_tier is Premium and account_kind is BlockBlobStorage or FileStorage."
  type        = bool
  default     = false
}

variable "immutability_policy" {
  description = "Account-level immutability policy configuration."
  type = object({
    allow_protected_append_writes = bool
    state                         = string
    period_since_creation_in_days = number
  })
  default = null
  
  validation {
    condition     = var.immutability_policy == null || contains(["Disabled", "Unlocked", "Locked"], try(var.immutability_policy.state, ""))
    error_message = "immutability_policy.state must be one of: Disabled, Unlocked, Locked."
  }
}

variable "sas_policy" {
  description = "SAS policy configuration for the storage account."
  type = object({
    expiration_period = string
    expiration_action = optional(string, "Log")
  })
  default = null
}

variable "allowed_copy_scope" {
  description = "Restrict copy operations to Storage Accounts within an AAD tenant or with Private Links to the same VNet."
  type        = string
  default     = null
  
  validation {
    condition     = var.allowed_copy_scope == null || contains(["AAD", "PrivateLink"], var.allowed_copy_scope)
    error_message = "allowed_copy_scope must be either AAD or PrivateLink."
  }
}

variable "dns_endpoint_type" {
  description = "DNS endpoint type. Standard or AzureDnsZone (requires PartitionedDns feature)."
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "AzureDnsZone"], var.dns_endpoint_type)
    error_message = "dns_endpoint_type must be either Standard or AzureDnsZone."
  }
}

variable "restore_policy" {
  description = "Blob restore policy configuration. Requires delete_retention_policy, versioning_enabled, and change_feed_enabled to be true. Cannot be used with dns_endpoint_type AzureDnsZone or when account_kind is Storage."
  type = object({
    days = number
  })
  default = null
  
  validation {
    condition     = var.restore_policy == null || (try(var.restore_policy.days, 0) >= 1 && try(var.restore_policy.days, 0) <= 365)
    error_message = "restore_policy.days must be between 1 and 365."
  }
}

variable "change_feed_retention_in_days" {
  description = "Change feed events retention in days. Between 1 and 146000 days. Null indicates infinite retention. Cannot be configured when account_kind is Storage."
  type        = number
  default     = null
  
  validation {
    condition     = var.change_feed_retention_in_days == null || (try(var.change_feed_retention_in_days >= 1 && var.change_feed_retention_in_days <= 146000, false))
    error_message = "change_feed_retention_in_days must be between 1 and 146000."
  }
}

variable "default_service_version" {
  description = "The API Version which should be used by default for requests to the Data Plane API if an incoming request doesn't specify an API Version."
  type        = string
  default     = null
}

variable "permanent_delete_enabled" {
  description = "Indicates whether permanent deletion of soft deleted blob versions and snapshots is allowed. Cannot be true if restore_policy is defined."
  type        = bool
  default     = false
}

variable "file_shares" {
  description = "Map of file shares to create. Key is the share name."
  type = map(object({
    quota                = number
    enabled_protocol     = optional(string)
    metadata             = optional(map(string))
    access_tier          = optional(string)
    acl                  = optional(list(object({
      id          = string
      access_policy = optional(object({
        permissions = string
        start       = optional(string)
        expiry      = optional(string)
      }))
    })))
  }))
  default = {}
  
  validation {
    condition     = alltrue([for k, v in var.file_shares : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", k)) && length(k) >= 3 && length(k) <= 63])
    error_message = "Share names must be 3-63 characters, start/end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
  
  validation {
    condition     = alltrue([for k, v in var.file_shares : v.quota >= 1 && v.quota <= 102400])
    error_message = "Quota must be between 1 and 102400 GB."
  }
}

variable "tables" {
  description = "Map of storage tables to create. Key is the table name. Value is an object with optional ACL configuration."
  type = map(object({
    acl = optional(list(object({
      id          = string
      access_policy = optional(object({
        permissions = string
        start       = optional(string)
        expiry      = optional(string)
      }))
    })))
  }))
  default = {}
  
  validation {
    condition     = alltrue([for k, v in var.tables : can(regex("^[A-Za-z][A-Za-z0-9]{2,62}$", k))])
    error_message = "Table names must be 3-63 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "queues" {
  description = "Map of storage queues to create. Key is the queue name. Value is an object with optional metadata."
  type = map(object({
    metadata = optional(map(string))
  }))
  default = {}
  
  validation {
    condition     = alltrue([for k, v in var.queues : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", k)) && length(k) >= 3 && length(k) <= 63])
    error_message = "Queue names must be 3-63 characters, start/end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "management_policy" {
  description = "Storage account lifecycle management policy configuration."
  type = object({
    rules = list(object({
      name    = string
      enabled = bool
      filters = object({
        prefix_match = optional(list(string))
        blob_types   = list(string)
        match_blob_index_tag = optional(list(object({
          name      = string
          operation = optional(string)
          value     = string
        })))
      })
      actions = object({
        base_blob = optional(object({
          tier_to_cool_after_days_since_modification_greater_than        = optional(number)
          tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
          tier_to_archive_after_days_since_modification_greater_than     = optional(number)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_cold_after_days_since_modification_greater_than        = optional(number)
          tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
          delete_after_days_since_modification_greater_than              = optional(number)
          delete_after_days_since_last_access_time_greater_than          = optional(number)
          auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        }))
        snapshot = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
          delete_after_days_since_creation_greater_than                  = optional(number)
        }))
        version = optional(object({
          change_tier_to_archive_after_days_since_creation               = optional(number)
          tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
          change_tier_to_cool_after_days_since_creation                  = optional(number)
          tier_to_cold_after_days_since_creation_greater_than            = optional(number)
          delete_after_days_since_creation                               = optional(number)
        }))
      })
    }))
  })
  default = null
}