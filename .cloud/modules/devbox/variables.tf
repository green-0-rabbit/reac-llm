variable "project" {
  description = "Project name for tagging resources."
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the DevBox VM and related resources (NIC/NSG/disks) will be created."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., westeurope)."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the DevBox VM NIC will be attached."
}

variable "vm_name" {
  type        = string
  default     = "vm-devbox"
  description = "Name of the DevBox VM."
}

variable "nic_name" {
  type        = string
  default     = null
  description = "Optional NIC name (defaults to <vm_name>-nic when null)."
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
  description = "VM size (defaults to Standard_B2s)."
}

variable "admin_username" {
  type        = string
  default     = "devadmin"
  description = "Admin username for the VM."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Local admin password."
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
  description = "Data disk size in GB."
}

# Ubuntu LTS defaults (Noble)
variable "image_publisher" {
  type        = string
  default     = "Canonical"
  description = "Source image publisher."
}

variable "image_offer" {
  type        = string
  default     = "ubuntu-24_04-lts"
  description = "Source image offer (Ubuntu Noble)."
}

variable "image_sku" {
  type        = string
  default     = "server"
  description = "Source image SKU (Ubuntu 24.04 LTS)."
}

variable "custom_image_id" {
  type        = string
  default     = null
  description = "Optional custom image ID to use instead of a marketplace image."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_managed_identity" {
  type        = bool
  default     = true
  description = "Enable system-assigned managed identity on the VM."
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Map of environment variables to inject into /etc/sbx.env"
}

variable "enable_public_ip" {
  type    = bool
  default = false
}

variable "enable_bastion_host" {
  type        = bool
  default     = true
  description = "Enable Azure Bastion host creation for the DevBox."
}

variable "bastion_subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for AzureBastionSubnet."
}

variable "bastion_name" {
  type        = string
  default     = null
  description = "Optional Bastion host name override."
}

variable "bastion_pip_name" {
  type        = string
  default     = null
  description = "Optional Bastion public IP name override."
}
