variable "private_dns_zone_rg" {
  type        = string
  description = "Resource group that hosts the Private DNS zone."
  validation {
    condition     = length(var.private_dns_zone_rg) > 0
    error_message = "private_dns_zone_rg must be provided (the zone's RG from the backbone stack)."
  }
}

# (Optional) CIDRs allowed to reach 443 on the registry (ACA subnets)
variable "allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to reach HTTPS; pass ACA subnets here."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the Nexus VM and related resources (NIC/NSG/disks) will be created."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., westeurope)."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the Nexus VM NIC will be attached."
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "Address prefix of the Azure Bastion subnet (for NSG rules)."
}

variable "vm_name" {
  type        = string
  default     = "vm-nexus"
  description = "Name of the Nexus VM."
}

variable "nic_name" {
  type        = string
  default     = null
  description = "Optional NIC name (defaults to <vm_name>-nic when null)."
}

variable "nsg_name" {
  type        = string
  default     = null
  description = "Optional NSG name (defaults to <vm_name>-nsg when null)."
}

variable "osdisk_name" {
  type        = string
  default     = null
  description = "Optional OS disk name (defaults to <vm_name>-osdisk when null)."
}

variable "datadisk_name" {
  type        = string
  default     = null
  description = "Optional data disk name (defaults to <vm_name>-data when null)."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "VM size for Nexus (POC-friendly default)."
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Admin username for the VM."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Local admin password (used with Azure Bastion)."
}

variable "os_disk_sku" {
  type        = string
  default     = "Standard_LRS"
  description = "OS disk storage account type."
}

variable "data_disk_sku" {
  type        = string
  default     = "Standard_LRS"
  description = "Data disk storage account type."
}

variable "data_disk_size_gb" {
  type        = number
  default     = 100
  description = "Data disk size in GB for Nexus blob storage."
}

# Ubuntu LTS defaults (Jammy)
variable "image_publisher" {
  type        = string
  default     = "Canonical"
  description = "Source image publisher."
}

variable "image_offer" {
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
  description = "Source image offer (Ubuntu Jammy)."
}

variable "image_sku" {
  type        = string
  default     = "22_04-lts"
  description = "Source image SKU (Ubuntu 22.04 LTS)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to created resources."
}

variable "ui_allowed_cidrs" {
  type        = list(string)
  default     = ["AzureBastion"]
  description = "CIDRs (or service tags) allowed to access Nexus UI on 8081 (default allows AzureBastion)."
}

# Private DNS — provided by the backbone (.cloud/tf-infra)
variable "dns_record_name" {
  type        = string
  default     = "nexus"
  description = "Relative record name to create in the private zone (e.g., 'nexus' -> nexus.<zone>)."
}

variable "private_dns_zone_name" {
  type        = string
  description = "Existing Private DNS zone name created by the backbone (e.g., sbx.example.com)."
  validation {
    condition     = length(var.private_dns_zone_name) > 0
    error_message = "private_dns_zone_name must be provided (e.g., 'sbx.example.com')."
  }
}

