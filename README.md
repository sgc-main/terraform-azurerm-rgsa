# Terraform Azure Storage Account Module (terraform-azr-rgsa)

Comprehensive Terraform module for creating and managing Azure Storage Accounts with support for remote state storage, complete service configurations, and enterprise-grade security features.

## Features

- **Flexible Naming**: Deterministic naming convention or custom name override
- **Resource Group Management**: Create new or use existing resource groups
- **Complete Storage Services**: Blob containers, file shares, tables, and queues with for_each support
- **Advanced Security**: Network rules, private endpoints, managed identities, encryption options
- **Lifecycle Management**: Automated tiering and retention policies
- **Multi-Protocol Support**: SMB, NFS, SFTP with proper validations
- **Azure Files Authentication**: AD/AADDS/AADKERB integration
- **Compliance Features**: Immutability policies, SAS policies, management locks
- **Disaster Recovery**: Geo-redundant replication support (RA-GRS/RA-GZRS)

---

## Quick Start

### Basic Terraform Remote State Storage

```hcl
module "tfstate" {
  source = "./terraform-azr-rgsa"
  
  location               = "eastus"
  sa_prefix              = "comtfstate"
  subscription_shortcode = "app"
  environment            = "dev"
  
  # Creates: comtfstateappdev (storage account)
  # Creates: rg-comtfstate-app-dev-tfstate (resource group)
}
```

### Custom Named Storage Account

```hcl
module "storage" {
  source = "./terraform-azr-rgsa"
  
  location                        = "eastus"
  storage_account_name_override   = "mystorageacct123"
  resource_group_name_override    = "my-custom-rg"
  
  containers = {
    data = {
      container_access_type = "private"
    }
  }
}
```

---

## Naming Convention

### Deterministic Naming (Default)

**Storage Account**: `<sa_prefix><subscription_shortcode><environment>`  
**Resource Group**: `rg-<sa_prefix>-<subscription_shortcode>-<environment>-<rg_suffix>`

**Example:**
- `sa_prefix = "comtfstate"`
- `subscription_shortcode = "app"`
- `environment = "dev"`
- Result: `comtfstateappdev` (storage account), `rg-comtfstate-app-dev-tfstate` (resource group)

**Constraints:**
- Storage Account: 3-24 characters, lowercase letters and numbers only
- Environment: Exactly 3 characters
- Auto-validated to ensure total length ≤ 24 characters

### Custom Naming (Override)

Use `storage_account_name_override` and `resource_group_name_override` to bypass deterministic naming:

```hcl
storage_account_name_override = "mystorageacct123"  # 3-24 chars, lowercase alphanumeric
resource_group_name_override  = "my-custom-rg"      # 1-90 chars, alphanumeric + _.-()
```

When using overrides, `sa_prefix`, `subscription_shortcode`, and `environment` are optional.

---

## Architecture

### Disaster Recovery Model

Single Storage Account with Azure-native geo-redundant replication:

- **RA-GRS** (Recommended): Locally redundant in primary region + geo-redundant to paired region
- **RA-GZRS** (Premium): Zone-redundant in primary + geo-redundant to paired region

**Benefits:**
- Automatic cross-region replication
- Read access from secondary region
- Azure-managed failover capabilities
- No manual replication required

---

## Usage Examples

See [examples/](./examples/) directory for complete working examples:

- **[tfstate-backend](./examples/tfstate-backend/)** - Terraform remote state storage with best practices
- **[custom-names](./examples/custom-names/)** - Storage account with name overrides and full configuration

---

## Input Variables

### Core Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `location` | string | **required** | Azure region for resources |
| `storage_account_name_override` | string | `null` | Override storage account name (3-24 chars, lowercase alphanumeric) |
| `resource_group_name_override` | string | `null` | Override resource group name (1-90 chars) |
| `sa_prefix` | string | `"comtfstate"` | Prefix for deterministic storage account name |
| `subscription_shortcode` | string | `""` | Subscription abbreviation for deterministic naming |
| `environment` | string | `""` | 3-letter environment code (dev, prd, stg) |
| `rg_suffix` | string | `"tfstate"` | Suffix for resource group name |
| `create_resource_group` | bool | `true` | Create new RG or use existing |
| `existing_resource_group_name` | string | `null` | Name of existing RG (when `create_resource_group = false`) |

### Storage Account Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `account_kind` | string | `"StorageV2"` | Storage account kind (StorageV2, BlobStorage, BlockBlobStorage, FileStorage, Storage) |
| `account_tier` | string | `"Standard"` | Account tier (Standard, Premium) |
| `replication_type` | string | `"RAGRS"` | Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS) |
| `is_hns_enabled` | bool | `false` | Enable Hierarchical Namespace (Data Lake Gen2) |
| `nfsv3_enabled` | bool | `false` | Enable NFSv3 protocol |
| `sftp_enabled` | bool | `false` | Enable SFTP (requires `is_hns_enabled = true`) |
| `large_file_share_enabled` | bool | `false` | Enable large file shares (auto-enabled for FileStorage) |
| `local_user_enabled` | bool | `true` | Enable local user authentication |

### Security & Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `min_tls_version` | string | `"TLS1_2"` | Minimum TLS version |
| `public_network_access_enabled` | bool | `false` | Allow public network access |
| `shared_access_key_enabled` | bool | `true` | Enable shared key authentication |
| `allowed_copy_scope` | string | `null` | Restrict copy scope (AAD, PrivateLink) |
| `dns_endpoint_type` | string | `"Standard"` | DNS endpoint type (Standard, AzureDnsZone) |
| `network_rules` | object | `null` | Network access rules with private link support |
| `managed_identity_type` | string | `null` | Managed identity type (SystemAssigned, UserAssigned, SystemAssigned, UserAssigned) |
| `managed_identity_ids` | list(string) | `null` | User-assigned managed identity IDs |

### Encryption

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `infrastructure_encryption_enabled` | bool | `false` | Enable infrastructure encryption |
| `queue_encryption_key_type` | string | `"Service"` | Queue encryption key type (Service, Account) |
| `table_encryption_key_type` | string | `"Service"` | Table encryption key type (Service, Account) |

### Blob Properties

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `versioning_enabled` | bool | `true` | Enable blob versioning |
| `change_feed_enabled` | bool | `false` | Enable change feed |
| `change_feed_retention_in_days` | number | `null` | Change feed retention (1-146000 days) |
| `last_access_time_enabled` | bool | `false` | Enable last access time tracking |
| `blob_soft_delete_retention_days` | number | `14` | Blob soft delete retention days |
| `container_soft_delete_retention_days` | number | `14` | Container soft delete retention days |
| `permanent_delete_enabled` | bool | `false` | Allow permanent deletion of soft deleted items |
| `default_service_version` | string | `null` | Default API version for Data Plane |
| `restore_policy` | object | `null` | Point-in-time restore configuration |
| `cors_rule` | object | `null` | CORS rules for blob service |

### Storage Services

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `containers` | map(object) | `{tfstate = {...}}` | Blob containers to create |
| `file_shares` | map(object) | `{}` | File shares with quota and ACL support |
| `tables` | map(object) | `{}` | Storage tables with ACL support |
| `queues` | map(object) | `{}` | Storage queues with metadata |

### Advanced Features

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `azure_files_authentication` | object | `null` | Azure Files AD authentication |
| `routing` | object | `null` | Network routing preferences |
| `custom_domain` | object | `null` | Custom domain configuration |
| `immutability_policy` | object | `null` | Account-level immutability policy |
| `sas_policy` | object | `null` | SAS token expiration policy |
| `management_policy` | object | `null` | Lifecycle management rules |
| `static_website` | object | `null` | Static website hosting configuration |
| `share_properties` | object | `null` | File share service properties |
| `queue_properties` | object | `null` | Queue service properties |

### Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lock_resource_group` | bool | `true` | Apply CanNotDelete lock to resource group |
| `lock_storage_account` | bool | `true` | Apply CanNotDelete lock to storage account |
| `tags` | map(string) | `{}` | Tags to apply to all resources |

---

## Outputs

### Resource Group

| Output | Description |
|--------|-------------|
| `resource_group_name` | Resource group name (created or existing) |
| `resource_group_id` | Resource group ID |
| `resource_group_location` | Resource group location |

### Storage Account

| Output | Description |
|--------|-------------|
| `storage_account_name` | Storage account name |
| `storage_account_id` | Storage account ID |
| `storage_account_tier` | Storage account tier |
| `storage_account_kind` | Storage account kind |
| `storage_account_replication_type` | Replication type |
| `storage_account_primary_location` | Primary location |
| `storage_account_secondary_location` | Secondary location (geo-redundant) |

### Endpoints

| Output | Description |
|--------|-------------|
| `primary_blob_endpoint` | Primary blob endpoint URL |
| `secondary_blob_endpoint` | Secondary blob endpoint URL |
| `primary_blob_host` | Primary blob host (no protocol) |
| `primary_queue_endpoint` | Primary queue endpoint |
| `primary_table_endpoint` | Primary table endpoint |
| `primary_file_endpoint` | Primary file endpoint |
| `primary_dfs_endpoint` | Primary DFS endpoint (Data Lake) |
| `primary_web_endpoint` | Primary web endpoint (static website) |

### Storage Services

| Output | Description |
|--------|-------------|
| `containers` | Map of all containers with details |
| `container_names` | List of container names |
| `container_ids` | Map of container names to IDs |
| `file_shares` | Map of all file shares with details |
| `tables` | Map of all tables with details |
| `queues` | Map of all queues with details |

### Sensitive Outputs

| Output | Description |
|--------|-------------|
| `primary_connection_string` | Primary connection string (sensitive) |
| `secondary_connection_string` | Secondary connection string (sensitive) |
| `primary_access_key` | Primary access key (sensitive) |
| `secondary_access_key` | Secondary access key (sensitive) |

### Other

| Output | Description |
|--------|-------------|
| `storage_account_principal_id` | Managed identity principal ID |
| `storage_account_tenant_id` | Managed identity tenant ID |
| `management_policy_id` | Lifecycle management policy ID |

---

## Feature Constraints

### HNS (Hierarchical Namespace)
- Can be enabled when `account_tier = Standard` OR (`account_tier = Premium` AND `account_kind = BlockBlobStorage`)

### NFSv3
- Requires: `is_hns_enabled = true`
- Requires: `account_tier = Standard` AND `account_kind = StorageV2` OR `account_tier = Premium` AND `account_kind = BlockBlobStorage`
- Requires: `replication_type` in `[LRS, RAGRS]`

### SFTP
- Requires: `is_hns_enabled = true`

### Infrastructure Encryption
- Only supported when `account_kind = StorageV2` OR (`account_tier = Premium` AND `account_kind` in `[BlockBlobStorage, FileStorage]`)

### Queue Properties
- Only configurable when `account_tier = Standard` AND `account_kind` in `[Storage, StorageV2]`

### Static Website
- Only supported when `account_kind` in `[StorageV2, BlockBlobStorage]`

### Share Properties
- Only configurable when (`account_tier = Standard` AND `account_kind` in `[Storage, StorageV2]`) OR (`account_tier = Premium` AND `account_kind = FileStorage`)

---

## Best Practices

### Remote State Storage

1. **Use Dedicated Storage Account**: Isolate Terraform state from application data
2. **Enable Versioning**: Protects against accidental state corruption
3. **Enable Soft Delete**: Allows recovery of deleted state files
4. **Use Private Endpoints**: Restrict access to specific networks
5. **Enable Management Locks**: Prevent accidental deletion
6. **Use Geo-Redundant Replication**: RA-GRS or RA-GZRS for disaster recovery
7. **Implement Network Rules**: Restrict access by IP when not using private endpoints
8. **Enable Diagnostic Logging**: Monitor access and operations for security insights

### General Storage

1. **Use Managed Identities**: Avoid storing access keys
2. **Implement Network Rules**: Restrict access by IP/VNet
3. **Enable Lifecycle Policies**: Automate data tiering and cleanup
4. **Use Immutability Policies**: For compliance and data protection
5. **Monitor Access**: Enable diagnostic settings and logging

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.100.0 |

---

## Authentication

This module uses the AzureRM provider's authentication. Common methods:

### Azure CLI (Recommended for Development)

```bash
az login
az account set --subscription <subscription-id>
```

### Service Principal

```bash
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

### Managed Identity (Azure Resources)

Automatically used when running from Azure VMs, App Services, or Azure DevOps agents with managed identity.

---

## Examples

See the [examples/](./examples/) directory for complete, working examples.

---

## Contributing

Contributions are welcome! Please ensure:
- All variables are properly documented
- Examples are provided for new features
- Validation rules are in place for inputs
- Output values are comprehensive

---

## License

This module is maintained for internal use. Refer to your organization's licensing policies.

---

## Support

For issues, questions, or feature requests, please contact the infrastructure team or create an issue in the repository.

- Terraform always references the same storage account name
- Data is asynchronously replicated to the paired Azure region
- In the event of a regional outage, a storage account failover is initiated
- Azure automatically updates DNS so the same endpoint serves traffic from the new primary region

No second storage account, no replication rules, and no backend reconfiguration are required.

---

## Security & Hardening Defaults

This module enforces the following best practices:

- HTTPS-only traffic
- Minimum TLS version: TLS 1.2
- Public access disabled
- Infrastructure encryption enabled
- Blob versioning enabled
- Soft delete enabled for:
  - Blobs
  - Containers
- Private blob container for state
- Optional CanNotDelete management locks on:
  - Resource Group
  - Storage Account

---

## Usage Example

```hcl
module "tfstate" {
  source = "./terraform-azr-rgsa"

  location = "eastus"

  sa_prefix              = "comtfstate"
  subscription_shortcode = "app"
  environment            = "prd"

  replication_type = "RAGZRS"

  tags = {
    Owner  = "CloudOPS"
    System = "Terraform"
  }
}