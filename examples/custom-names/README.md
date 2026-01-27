# Custom Named Storage Account Example

This example demonstrates creating a fully-featured Azure Storage Account with custom names (bypassing deterministic naming) and all available storage services.

## What This Creates

- **Resource Group**: `rg-custom-storage-prod` (custom named)
- **Storage Account**: `mystorageacct123` (custom named)
- **Blob Containers**: `data`, `backups`, `public`
- **File Shares**: `documents` (100GB), `apps` (50GB)
- **Tables**: `logs`, `metrics`
- **Queues**: `tasks`, `notifications`
- **Managed Identity**: System-assigned identity
- **Lifecycle Policies**: Automated tiering and cleanup
- **Static Website**: Enabled with index.html
- **SFTP Access**: Enabled (requires Azure AD authentication)
- **Advanced Features**: HNS (Data Lake Gen2), large file shares, encryption

## Key Features Demonstrated

### Name Override Variables

Instead of using deterministic naming (`sa_prefix` + `subscription_shortcode` + `environment`), this example uses:

```hcl
storage_account_name_override = "mystorageacct123"
resource_group_name_override   = "rg-custom-storage-prod"
```

This allows complete control over resource naming while still benefiting from all module features.

### Complete Storage Services

All four Azure Storage services are configured:

1. **Blob Storage**: 3 containers with different access levels
2. **File Shares**: SMB shares with quotas and ACLs
3. **Tables**: NoSQL key-value storage with ACLs
4. **Queues**: Message queuing for async processing

### Advanced Security

- System-assigned managed identity
- Network rules (configurable)
- TLS 1.2 minimum
- Infrastructure encryption (double encryption)
- Management locks on RG and SA

### Lifecycle Management

Automated data lifecycle policies:
- **Hot → Cool**: After 30 days of inactivity
- **Cool → Archive**: After 90 days
- **Delete**: After 365 days for data/, 180 days for backups/
- **Snapshot cleanup**: Delete after 30 days

### Data Lake Gen2

Hierarchical namespace enabled for big data analytics:
- Optimized for large-scale data processing
- SFTP access enabled
- Compatible with Azure Databricks, Synapse, HDInsight

## Prerequisites

1. **Azure CLI**: Authenticate with sufficient permissions
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform**: Version >= 1.5.0

3. **Permissions**: Contributor or Storage Account Contributor role

## Usage

### 1. Customize Variables

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
location              = "westus2"
storage_account_name  = "mycompanystorage"
resource_group_name   = "rg-mycompany-prod"
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Storage Services

#### Blob Storage

```bash
# Using Azure CLI
az storage blob upload \
  --account-name mystorageacct123 \
  --container-name data \
  --name myfile.txt \
  --file ./myfile.txt \
  --auth-mode login
```

#### File Share (SMB)

**Linux**:
```bash
sudo mkdir /mnt/documents
sudo mount -t cifs //mystorageacct123.file.core.windows.net/documents /mnt/documents \
  -o vers=3.0,username=mystorageacct123,password=<access-key>,dir_mode=0777,file_mode=0777
```

**Windows**:
```powershell
net use Z: \\mystorageacct123.file.core.windows.net\documents /user:Azure\mystorageacct123 <access-key>
```

#### Table Storage

```python
from azure.data.tables import TableServiceClient

service = TableServiceClient.from_connection_string(conn_str="<connection-string>")
table_client = service.get_table_client("logs")
table_client.create_entity({"PartitionKey": "logs", "RowKey": "001", "message": "test"})
```

#### Queue Storage

```python
from azure.storage.queue import QueueClient

queue = QueueClient.from_connection_string(conn_str="<connection-string>", queue_name="tasks")
queue.send_message("Process this task")
```

#### SFTP Access

```bash
# Connect via SFTP (requires local user configuration)
sftp <local-user>@mystorageacct123.blob.core.windows.net
```

## Customization Options

### Enable Azure Files AD Authentication

Uncomment the `azure_files_authentication` block in `main.tf`:

```hcl
azure_files_authentication = {
  directory_type = "AADDS"
  active_directory = {
    domain_name         = "contoso.com"
    domain_guid         = "12345678-1234-1234-1234-123456789012"
    domain_sid          = "S-1-5-21-..."
    storage_sid         = "S-1-5-21-..."
    forest_name         = "contoso.com"
    netbios_domain_name = "CONTOSO"
  }
}
```

### Restrict Network Access

Change network rules to deny by default:

```hcl
network_rules = {
  default_action = "Deny"
  ip_rules       = ["203.0.113.0/24"]  # Your office IP
  virtual_network_subnet_ids = [
    "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>"
  ]
}
```

### Add More Containers/Shares

Extend the maps:

```hcl
containers = {
  data    = { ... }
  backups = { ... }
  archive = {
    name                  = "archive"
    container_access_type = "private"
    metadata = { tier = "archive" }
  }
}
```

### Modify Lifecycle Policies

Adjust retention periods in `management_policy`:

```hcl
actions = {
  base_blob = {
    tier_to_cool_after_days_since_modification_greater_than    = 60  # Changed from 30
    tier_to_archive_after_days_since_modification_greater_than = 180 # Changed from 90
    delete_after_days_since_modification_greater_than          = 730 # Changed from 365
  }
}
```

## Outputs

After deployment, view outputs:

```bash
terraform output
```

Key outputs:
- `storage_account_name`: For SDK/CLI access
- `primary_blob_endpoint`: Blob service URL
- `primary_file_endpoint`: File share service URL
- `containers`: All container details
- `file_shares`: All share details
- `primary_access_key`: Access key (sensitive)

## Static Website

With `static_website` enabled, deploy a website:

```bash
# Upload index.html
az storage blob upload \
  --account-name mystorageacct123 \
  --container-name '$web' \
  --name index.html \
  --file ./index.html \
  --auth-mode login

# Access at the web endpoint
echo "https://mystorageacct123.z13.web.core.windows.net/"
```

## Cost Optimization

### Storage Classes

The lifecycle policy automatically moves data to cheaper storage:
- **Hot**: Frequent access ($0.0184/GB/month)
- **Cool**: Infrequent access ($0.01/GB/month)
- **Archive**: Rare access ($0.002/GB/month)

### Example Cost (100GB over 1 year)

- **Month 1-3**: Hot tier = 100GB × $0.0184 × 3 = **$5.52**
- **Month 4-12**: Cool tier = 100GB × $0.01 × 9 = **$9.00**
- **Total Year 1**: **$14.52** (vs **$22.08** always-hot)

### Reduce Costs Further

1. Lower lifecycle thresholds (tier to cool faster)
2. Use GRS instead of RAGRS if read-access not needed
3. Delete old blob versions more aggressively

## Security Checklist

- [x] TLS 1.2 minimum enforced
- [x] Infrastructure encryption enabled (double encryption)
- [x] Managed identity for Azure AD authentication
- [x] Network rules configured (adjust for production)
- [x] Soft delete enabled (14-day retention)
- [x] Versioning enabled for audit trail
- [x] Management locks prevent accidental deletion
- [x] Allowed copy scope restricted to AAD
- [ ] Private endpoints configured (add VNet integration)
- [ ] Diagnostic logging enabled (configure separately)
- [ ] Key rotation policy established (manual or automated)

## Troubleshooting

### SFTP Connection Fails

**Error**: "Permission denied"

**Solution**: Configure local users via Azure Portal or CLI:
```bash
az storage account local-user create \
  --account-name mystorageacct123 \
  --resource-group rg-custom-storage-prod \
  --name myuser \
  --home-directory data \
  --permission-scope permissions=rwdlc service=blob resource-name=data
```

### File Share Mount Fails

**Error**: "Access denied"

**Solution**: Get access key and use in mount command:
```bash
az storage account keys list \
  --account-name mystorageacct123 \
  --resource-group rg-custom-storage-prod
```

### Lifecycle Policy Not Working

**Issue**: Blobs not moving to cool tier

**Solution**: Ensure `last_access_time_enabled = true` and wait up to 48 hours for policy execution.

## Clean Up

To destroy all resources:

```bash
# Remove management locks first (via Portal or CLI)
az lock delete --name DoNotDeleteLock-SA --resource-group rg-custom-storage-prod
az lock delete --name DoNotDeleteLock-RG --resource-group rg-custom-storage-prod

# Then destroy
terraform destroy
```

## References

- [Azure Storage Account Documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Azure Files SMB/NFS](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction)
- [Lifecycle Management Policies](https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)
- [SFTP Support](https://docs.microsoft.com/en-us/azure/storage/blobs/secure-file-transfer-protocol-support)
