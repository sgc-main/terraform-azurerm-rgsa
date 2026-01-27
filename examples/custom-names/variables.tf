variable "location" {
  description = "Azure region for the storage account"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Custom name for the storage account (3-24 characters, lowercase alphanumeric only)"
  type        = string
  default     = "mystorageacct123"
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "Custom name for the resource group"
  type        = string
  default     = "rg-custom-storage-prod"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 characters and can contain alphanumerics, underscores, periods, hyphens, and parentheses."
  }
}
