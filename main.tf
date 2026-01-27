terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

locals {
  # Validate deterministic naming inputs when override is not provided
  _validate_deterministic_naming = var.storage_account_name_override == null ? (
    var.sa_prefix != "" && var.subscription_shortcode != "" && var.environment != "" ? true : tobool("When storage_account_name_override is not provided, sa_prefix, subscription_shortcode, and environment are required.")
  ) : true

  storage_account_name = var.storage_account_name_override != null ? var.storage_account_name_override : lower(
    format(
      "%s%s%s",
      var.sa_prefix,
      var.subscription_shortcode,
      var.environment
    )
  )

  # Validate storage account name length
  _validate_sa_length = length(local.storage_account_name) >= 3 && length(local.storage_account_name) <= 24 ? true : tobool(
    "Storage account name '${local.storage_account_name}' is ${length(local.storage_account_name)} characters. Must be 3-24 characters. Adjust sa_prefix (${length(var.sa_prefix)}), subscription_shortcode (${length(var.subscription_shortcode)}), or environment (${length(var.environment)})."
  )

  resource_group_name = var.resource_group_name_override != null ? var.resource_group_name_override : lower(
    format(
      "rg-%s-%s-%s-%s",
      var.sa_prefix,
      var.subscription_shortcode,
      var.environment,
      var.rg_suffix
    )
  )

  # Use created or existing resource group
  rg_name     = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  rg_location = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.existing_resource_group_name != null ? var.existing_resource_group_name : local.resource_group_name
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = merge(var.tags, { Name = local.resource_group_name })
}

resource "azurerm_storage_account" "this" {
  name                = local.storage_account_name
  resource_group_name = local.rg_name
  location            = local.rg_location

  account_kind             = var.account_kind
  account_tier             = contains(["FileStorage", "BlockBlobStorage"], var.account_kind) ? "Premium" : var.account_tier
  account_replication_type = upper(var.replication_type)
  
  # Hierarchical Namespace (ADLS Gen2)
  is_hns_enabled = (var.account_tier == "Standard" || (var.account_tier == "Premium" && var.account_kind == "BlockBlobStorage")) ? var.is_hns_enabled : false
  
  # NFSv3 - requires HNS, specific tier/kind/replication
  nfsv3_enabled = var.nfsv3_enabled && var.is_hns_enabled && contains(["LRS", "RAGRS"], upper(var.replication_type)) && ((var.account_tier == "Standard" && var.account_kind == "StorageV2") || (var.account_tier == "Premium" && var.account_kind == "BlockBlobStorage")) ? true : false
  
  # SFTP requires HNS
  sftp_enabled = var.sftp_enabled && var.is_hns_enabled ? true : false
  
  # Large File Share - enabled by default for FileStorage
  large_file_share_enabled = var.account_kind == "FileStorage" ? true : var.large_file_share_enabled
  
  local_user_enabled = var.local_user_enabled
  
  # Encryption key types - cannot be Account when account_kind is Storage
  queue_encryption_key_type = var.account_kind == "Storage" && var.queue_encryption_key_type == "Account" ? "Service" : var.queue_encryption_key_type
  table_encryption_key_type = var.account_kind == "Storage" && var.table_encryption_key_type == "Account" ? "Service" : var.table_encryption_key_type
  
  # Infrastructure encryption - only for StorageV2 or Premium BlockBlobStorage/FileStorage
  infrastructure_encryption_enabled = (var.account_kind == "StorageV2" || (var.account_tier == "Premium" && contains(["BlockBlobStorage", "FileStorage"], var.account_kind))) ? var.infrastructure_encryption_enabled : false
  
  cross_tenant_replication_enabled = contains(["RAGRS", "RAGZRS"], var.replication_type) ? var.cross_tenant_replication_enabled : false
  min_tls_version                  = var.min_tls_version
  https_traffic_only_enabled       = true
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  public_network_access_enabled    = var.public_network_access_enabled
  default_to_oauth_authentication  = !var.shared_access_key_enabled
  shared_access_key_enabled        = var.shared_access_key_enabled
  
  allowed_copy_scope = var.allowed_copy_scope
  dns_endpoint_type  = var.dns_endpoint_type

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  blob_properties {
    versioning_enabled            = var.account_kind != "Storage" ? var.versioning_enabled : false
    last_access_time_enabled      = var.account_kind != "Storage" ? var.last_access_time_enabled : false
    change_feed_enabled           = var.account_kind != "Storage" ? var.change_feed_enabled : false
    change_feed_retention_in_days = var.account_kind != "Storage" && var.change_feed_enabled ? var.change_feed_retention_in_days : null
    default_service_version       = var.default_service_version

    delete_retention_policy {
      days                     = var.blob_soft_delete_retention_days
      permanent_delete_enabled = var.permanent_delete_enabled
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }

    dynamic "restore_policy" {
      for_each = var.restore_policy != null && var.account_kind != "Storage" && var.dns_endpoint_type != "AzureDnsZone" ? [1] : []
      content {
        days = var.restore_policy.days
      }
    }

    dynamic "cors_rule" {
      for_each = var.cors_rule != null ? [1] : []
      content {
        allowed_origins    = var.cors_rule.allowed_origins
        allowed_methods    = var.cors_rule.allowed_methods
        allowed_headers    = var.cors_rule.allowed_headers
        exposed_headers    = var.cors_rule.exposed_headers
        max_age_in_seconds = var.cors_rule.max_age_in_seconds
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
      
      dynamic "private_link_access" {
        for_each = lookup(var.network_rules, "private_link_access", null) != null ? var.network_rules.private_link_access : []
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = lookup(private_link_access.value, "endpoint_tenant_id", null)
        }
      }
    }
  }

  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication != null ? [1] : []
    content {
      directory_type = var.azure_files_authentication.directory_type
      
      dynamic "active_directory" {
        for_each = lookup(var.azure_files_authentication, "active_directory", null) != null ? [var.azure_files_authentication.active_directory] : []
        content {
          domain_name         = active_directory.value.domain_name
          domain_guid         = active_directory.value.domain_guid
          domain_sid          = lookup(active_directory.value, "domain_sid", null)
          storage_sid         = lookup(active_directory.value, "storage_sid", null)
          forest_name         = lookup(active_directory.value, "forest_name", null)
          netbios_domain_name = lookup(active_directory.value, "netbios_domain_name", null)
        }
      }
      
      default_share_level_permission = lookup(var.azure_files_authentication, "default_share_level_permission", null)
    }
  }

  dynamic "routing" {
    for_each = var.routing != null ? [1] : []
    content {
      publish_internet_endpoints  = lookup(var.routing, "publish_internet_endpoints", false)
      publish_microsoft_endpoints = lookup(var.routing, "publish_microsoft_endpoints", false)
      choice                      = lookup(var.routing, "choice", "MicrosoftRouting")
    }
  }

  dynamic "custom_domain" {
    for_each = var.custom_domain != null ? [1] : []
    content {
      name          = var.custom_domain.name
      use_subdomain = lookup(var.custom_domain, "use_subdomain", null)
    }
  }

  dynamic "immutability_policy" {
    for_each = var.immutability_policy != null ? [1] : []
    content {
      allow_protected_append_writes = var.immutability_policy.allow_protected_append_writes
      state                         = var.immutability_policy.state
      period_since_creation_in_days = var.immutability_policy.period_since_creation_in_days
    }
  }

  dynamic "sas_policy" {
    for_each = var.sas_policy != null ? [1] : []
    content {
      expiration_period = var.sas_policy.expiration_period
      expiration_action = lookup(var.sas_policy, "expiration_action", "Log")
    }
  }

  dynamic "queue_properties" {
    for_each = var.queue_properties != null && var.account_tier == "Standard" && contains(["Storage", "StorageV2"], var.account_kind) ? [1] : []
    content {
      dynamic "cors_rule" {
        for_each = lookup(var.queue_properties, "cors_rule", null) != null ? [var.queue_properties.cors_rule] : []
        content {
          allowed_origins    = cors_rule.value.allowed_origins
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_headers    = cors_rule.value.allowed_headers
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      dynamic "logging" {
        for_each = lookup(var.queue_properties, "logging", null) != null ? [var.queue_properties.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          write                 = logging.value.write
          version               = logging.value.version
          retention_policy_days = lookup(logging.value, "retention_policy_days", null)
        }
      }
      dynamic "minute_metrics" {
        for_each = lookup(var.queue_properties, "minute_metrics", null) != null ? [var.queue_properties.minute_metrics] : []
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = lookup(minute_metrics.value, "include_apis", null)
          retention_policy_days = lookup(minute_metrics.value, "retention_policy_days", null)
        }
      }
      dynamic "hour_metrics" {
        for_each = lookup(var.queue_properties, "hour_metrics", null) != null ? [var.queue_properties.hour_metrics] : []
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = lookup(hour_metrics.value, "include_apis", null)
          retention_policy_days = lookup(hour_metrics.value, "retention_policy_days", null)
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = var.static_website != null && contains(["StorageV2", "BlockBlobStorage"], var.account_kind) ? [1] : []
    content {
      index_document     = lookup(var.static_website, "index_document", null)
      error_404_document = lookup(var.static_website, "error_404_document", null)
    }
  }

  dynamic "share_properties" {
    for_each = var.share_properties != null && ((var.account_tier == "Standard" && contains(["Storage", "StorageV2"], var.account_kind)) || (var.account_tier == "Premium" && var.account_kind == "FileStorage")) ? [1] : []
    content {
      dynamic "cors_rule" {
        for_each = lookup(var.share_properties, "cors_rule", null) != null ? [var.share_properties.cors_rule] : []
        content {
          allowed_origins    = cors_rule.value.allowed_origins
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_headers    = cors_rule.value.allowed_headers
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      dynamic "retention_policy" {
        for_each = lookup(var.share_properties, "retention_policy", null) != null ? [var.share_properties.retention_policy] : []
        content {
          days = lookup(retention_policy.value, "days", 7)
        }
      }
      dynamic "smb" {
        for_each = lookup(var.share_properties, "smb", null) != null ? [var.share_properties.smb] : []
        content {
          versions                        = lookup(smb.value, "versions", null)
          authentication_types            = lookup(smb.value, "authentication_types", null)
          kerberos_ticket_encryption_type = lookup(smb.value, "kerberos_ticket_encryption_type", null)
          channel_encryption_type         = lookup(smb.value, "channel_encryption_type", null)
          multichannel_enabled            = lookup(smb.value, "multichannel_enabled", null)
        }
      }
    }
  }

  tags = merge(var.tags, { Name = local.storage_account_name })

  lifecycle {
    ignore_changes = [
      customer_managed_key,
    ]
  }
}

resource "azurerm_storage_management_policy" "this" {
  for_each = var.management_policy != null ? { enabled = true } : {}
  
  storage_account_id = azurerm_storage_account.this.id
  
  dynamic "rule" {
    for_each = var.management_policy.rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled
      
      filters {
        prefix_match = lookup(rule.value.filters, "prefix_match", null)
        blob_types   = rule.value.filters.blob_types
        
        dynamic "match_blob_index_tag" {
          for_each = lookup(rule.value.filters, "match_blob_index_tag", null) != null ? rule.value.filters.match_blob_index_tag : []
          content {
            name      = match_blob_index_tag.value.name
            operation = lookup(match_blob_index_tag.value, "operation", "==")
            value     = match_blob_index_tag.value.value
          }
        }
      }
      
      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value.actions, "base_blob", null) != null ? [rule.value.actions.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cool_after_days_since_modification_greater_than", null)
            tier_to_cool_after_days_since_last_access_time_greater_than    = lookup(base_blob.value, "tier_to_cool_after_days_since_last_access_time_greater_than", null)
            tier_to_archive_after_days_since_modification_greater_than     = lookup(base_blob.value, "tier_to_archive_after_days_since_modification_greater_than", null)
            tier_to_archive_after_days_since_last_access_time_greater_than = lookup(base_blob.value, "tier_to_archive_after_days_since_last_access_time_greater_than", null)
            tier_to_cold_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cold_after_days_since_modification_greater_than", null)
            tier_to_cold_after_days_since_last_access_time_greater_than    = lookup(base_blob.value, "tier_to_cold_after_days_since_last_access_time_greater_than", null)
            delete_after_days_since_modification_greater_than              = lookup(base_blob.value, "delete_after_days_since_modification_greater_than", null)
            delete_after_days_since_last_access_time_greater_than          = lookup(base_blob.value, "delete_after_days_since_last_access_time_greater_than", null)
            auto_tier_to_hot_from_cool_enabled                             = lookup(base_blob.value, "auto_tier_to_hot_from_cool_enabled", null)
          }
        }
        
        dynamic "snapshot" {
          for_each = lookup(rule.value.actions, "snapshot", null) != null ? [rule.value.actions.snapshot] : []
          content {
            change_tier_to_archive_after_days_since_creation = lookup(snapshot.value, "change_tier_to_archive_after_days_since_creation", null)
            tier_to_archive_after_days_since_last_tier_change_greater_than = lookup(snapshot.value, "tier_to_archive_after_days_since_last_tier_change_greater_than", null)
            change_tier_to_cool_after_days_since_creation    = lookup(snapshot.value, "change_tier_to_cool_after_days_since_creation", null)
            tier_to_cold_after_days_since_creation_greater_than = lookup(snapshot.value, "tier_to_cold_after_days_since_creation_greater_than", null)
            delete_after_days_since_creation_greater_than    = lookup(snapshot.value, "delete_after_days_since_creation_greater_than", null)
          }
        }
        
        dynamic "version" {
          for_each = lookup(rule.value.actions, "version", null) != null ? [rule.value.actions.version] : []
          content {
            change_tier_to_archive_after_days_since_creation = lookup(version.value, "change_tier_to_archive_after_days_since_creation", null)
            tier_to_archive_after_days_since_last_tier_change_greater_than = lookup(version.value, "tier_to_archive_after_days_since_last_tier_change_greater_than", null)
            change_tier_to_cool_after_days_since_creation    = lookup(version.value, "change_tier_to_cool_after_days_since_creation", null)
            tier_to_cold_after_days_since_creation_greater_than = lookup(version.value, "tier_to_cold_after_days_since_creation_greater_than", null)
            delete_after_days_since_creation                 = lookup(version.value, "delete_after_days_since_creation", null)
          }
        }
      }
    }
  }
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers
  
  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.container_access_type
  metadata              = lookup(each.value, "metadata", null)
}

resource "azurerm_storage_share" "this" {
  for_each = var.file_shares
  
  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  quota              = each.value.quota
  enabled_protocol   = lookup(each.value, "enabled_protocol", null)
  metadata           = lookup(each.value, "metadata", null)
  access_tier        = lookup(each.value, "access_tier", null)
  
  dynamic "acl" {
    for_each = lookup(each.value, "acl", null) != null ? each.value.acl : []
    content {
      id = acl.value.id
      
      dynamic "access_policy" {
        for_each = lookup(acl.value, "access_policy", null) != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = lookup(access_policy.value, "start", null)
          expiry      = lookup(access_policy.value, "expiry", null)
        }
      }
    }
  }
}

resource "azurerm_storage_table" "this" {
  for_each = var.tables
  
  name                 = each.key
  storage_account_name = azurerm_storage_account.this.name
  
  dynamic "acl" {
    for_each = lookup(each.value, "acl", null) != null ? each.value.acl : []
    content {
      id = acl.value.id
      
      dynamic "access_policy" {
        for_each = lookup(acl.value, "access_policy", null) != null ? [acl.value.access_policy] : []
        content {
          permissions = access_policy.value.permissions
          start       = lookup(access_policy.value, "start", null)
          expiry      = lookup(access_policy.value, "expiry", null)
        }
      }
    }
  }
}

resource "azurerm_storage_queue" "this" {
  for_each = var.queues
  
  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  metadata           = lookup(each.value, "metadata", null)
}

# Optional safety locks
resource "azurerm_management_lock" "rg" {
  count      = var.lock_resource_group && var.create_resource_group ? 1 : 0
  name       = "lock-tfstate-rg"
  scope      = azurerm_resource_group.this[0].id
  lock_level = "CanNotDelete"
  notes      = "Terraform state RG protection"
}

resource "azurerm_management_lock" "sa" {
  count      = var.lock_storage_account ? 1 : 0
  name       = "lock-tfstate-sa"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Terraform state storage account protection"
}