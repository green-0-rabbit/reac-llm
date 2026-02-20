variable "project" {
  description = "Project name for tagging resources."
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the Windows DevBox VM and related resources (NIC/NSG/disks) will be created."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., westeurope)."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the Windows DevBox VM NIC will be attached."
}

variable "vm_name" {
  type        = string
  default     = "vm-windevbox"
  description = "Name of the Windows DevBox VM."
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
  default     = "Standard_D2s_v3"
  description = "VM size (defaults to Standard_D2s_v3)."
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

# Windows 11 defaults
variable "image_publisher" {
  type        = string
  default     = "MicrosoftWindowsDesktop"
  description = "Source image publisher."
}

variable "image_offer" {
  type        = string
  default     = "windows-11"
  description = "Source image offer."
}

variable "image_sku" {
  type        = string
  default     = "win11-25h2-pro"
  description = "Source image SKU (Windows 11 25H2 Pro)."
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

variable "enable_public_ip" {
  type    = bool
  default = false
}

variable "enable_wsl_bootstrap" {
  type        = bool
  default     = false
  description = "Run first-boot bootstrap to install VS Code (machine), WSL Ubuntu, and base toolchain."
}

variable "enable_bastion_host" {
  type        = bool
  default     = true
  description = "Enable Azure Bastion host creation for the Windows DevBox."
}

variable "virtual_network_id" {
  type        = string
  default     = null
  description = "Virtual Network ID required for Developer Bastion."
}

variable "bastion_name" {
  type        = string
  default     = null
  description = "Optional Bastion host name override."
}
