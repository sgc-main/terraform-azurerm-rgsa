# Terraform Remote State Backend Example

This example demonstrates creating a dedicated Azure Storage Account for Terraform remote state with enterprise-grade security and disaster recovery.

## What This Creates

- **Resource Group**: `rg-comtfstate-app-dev-tfstate`
- **Storage Account**: `comtfstateappdev`
- **Blob Container**: `tfstate` (private access)
- **Management Locks**: Prevents accidental deletion of RG and SA
- **Geo-Redundant Storage**: RA-GRS replication to paired region
- **Advanced Security**: Private networking, encryption, soft delete, versioning

## Prerequisites

1. **Azure CLI**: Install and authenticate
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform**: Version >= 1.5.0

3. **Permissions**: Contributor role on the subscription

## Usage

### 1. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 2. Configure Backend in Your Projects

After the storage account is created, use the output to configure your Terraform backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-commmswtfstate-app-dev-tfstate"
    storage_account_name = "commmswtfstateappdev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"  # or project-specific: "myapp/terraform.tfstate"
  }
}
```

### 3. Authenticate for Backend Access

The backend requires authentication. Choose one method:

**Azure CLI (Development)**:
```bash
az login
```

**Service Principal (CI/CD)**:
```bash
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

**Managed Identity (Azure-hosted agents)**:
Automatically used when running from Azure VMs, Container Instances, or Azure DevOps agents with managed identity.

## Customization

### Change Location or Names

Edit `variables.tf` or pass values:

```bash
terraform apply \
  -var="location=westus2" \
  -var="subscription_shortcode=prod" \
  -var="environment=prd"
```

### Add Network Access

Uncomment and configure network rules in `main.tf`:

```hcl
network_rules = {
  ip_rules = ["203.0.113.0/24"]  # Your office IP range
  virtual_network_subnet_ids = [
    "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>"
  ]
}
```

### Extend Retention Periods

Modify blob soft delete and lifecycle policy:

```hcl
blob_soft_delete_retention_days = 60  # Extend to 60 days
```

## Security Features

| Feature | Configuration | Purpose |
|---------|---------------|---------|
| **Private Networking** | `public_network_access_enabled = false` | Block public internet access |
| **TLS 1.2** | `min_tls_version = "TLS1_2"` | Enforce modern encryption |
| **Versioning** | `versioning_enabled = true` | Track all state changes |
| **Soft Delete** | 30-day retention | Recover from accidental deletion |
| **Infrastructure Encryption** | Double encryption at rest | Enhanced data protection |
| **Management Locks** | CanNotDelete | Prevent accidental removal |
| **AAD-only Copy** | `allowed_copy_scope = "AAD"` | Restrict data exfiltration |

## Disaster Recovery

- **Replication**: RA-GRS (Read-Access Geo-Redundant Storage)
- **Secondary Region**: Automatic pairing (e.g., East US → West US)
- **Read Access**: Secondary endpoint available during primary region outage
- **Failover**: Azure-managed automatic failover capabilities

**Secondary Endpoint**: Available in outputs for read-only access during DR scenarios.

## Cost Estimate

**Monthly Cost** (as of 2024, approximate):
- Storage Account: ~$0.50 (minimal state file storage)
- RA-GRS Replication: ~$1.00 (geo-redundant copies)
- Network egress: Minimal for state operations

**Total**: ~$2/month per environment

## Lifecycle Management

The example includes a lifecycle policy to delete blob versions older than 90 days:

```hcl
management_policy = {
  rules = [
    {
      name = "deleteOldVersions"
      actions = {
        version = {
          delete_after_days_since_creation = 90
        }
      }
    }
  ]
}
```

This keeps storage costs low while maintaining recent version history.

## Best Practices

1. **One Storage Account Per Environment**: Isolate dev/stg/prd state
2. **Project-Specific Keys**: Use unique keys for each project: `myapp/terraform.tfstate`
3. **State Locking**: Automatically handled by Azure backend
4. **Backup Strategy**: Versioning + soft delete = comprehensive backup
5. **Monitor Access**: Enable diagnostic logging and review regularly
6. **Private Endpoints**: Configure VNet integration for production environments

## Troubleshooting

### Cannot Access Storage Account

**Error**: "Public access is disabled"

**Solution**: Add your IP to network rules or configure private endpoint access.

### Backend Initialization Fails

**Error**: "Failed to get existing workspaces"

**Solution**: Ensure authentication is configured (`az login` or service principal).

### Container Not Found

**Error**: "storage: service returned error: StatusCode=404"

**Solution**: Verify container name is `tfstate` and storage account exists.

## Outputs

Run `terraform output` to see:
- Resource group name
- Storage account name
- Backend configuration snippet
- Primary and secondary endpoints
- Connection strings (sensitive)

## Clean Up

**⚠️ Warning**: Deleting this storage account will destroy all Terraform state files!

To remove (requires removing management locks first):

```bash
# Remove locks via Azure Portal or CLI
az lock delete --name <lock-name> --resource-group <rg-name>

# Then destroy
terraform destroy
```

## References

- [Terraform Azure Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- [Azure Storage Security Guide](https://docs.microsoft.com/en-us/azure/storage/common/security-recommendations)
- [Azure Storage Redundancy](https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy)
