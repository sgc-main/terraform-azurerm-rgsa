variable "location" {
  description = "Azure region for the storage account"
  type        = string
  default     = "eastus"
}

variable "sa_prefix" {
  description = "Storage account prefix for deterministic naming"
  type        = string
  default     = "comtfstate"
}

variable "subscription_shortcode" {
  description = "Subscription abbreviation (e.g., mip, mmsw)"
  type        = string
  default     = "mip"
}

variable "environment" {
  description = "Environment code (exactly 3 characters: dev, stg, prd)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = length(var.environment) == 3
    error_message = "Environment must be exactly 3 characters (e.g., dev, stg, prd)."
  }
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
  default     = "Engineering"
}

variable "owner" {
  description = "Owner or team responsible for this resource"
  type        = string
  default     = "Infrastructure Team"
}
