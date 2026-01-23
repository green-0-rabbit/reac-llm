variable "project" {
  description = "Project name for tagging resources."
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the Bastion VM and related resources (NIC/NSG/disks) will be created."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., westeurope)."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the Bastion VM NIC will be attached."
}

variable "vm_name" {
  type        = string
  default     = "vm-bastion"
  description = "Name of the Bastion VM."
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
  description = "VM size for Bastion (POC-friendly default)."
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
  description = "Data disk size in GB for Bastion blob storage."
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
  type    = map(string)
  default = {}
}

variable "enable_managed_identity" {
  type        = bool
  default     = true
  description = "Enable system-assigned managed identity on the Bastion VM."
}

variable "acr_id" {
  type        = string
  default     = ""
  description = "Target ACR resource ID for AcrPush assignment. Leave empty to disable."
}

variable "acr_name" {
  type        = string
  default     = ""
  description = "ACR name (login server is <acr_name>.azurecr.io)."
}

variable "remote_acr_config" {
  type = object({
    username = string
    fqdn     = string
    images   = list(string)
  })
}

variable "remote_acr_password" {
  type      = string
  sensitive = true
}

variable "enable_public_ip" {
  type    = bool
  default = false
}

variable "enable_bastion_host" {
  type        = bool
  default     = true
  description = "Enable Azure Bastion host creation."
}

variable "vnet_id" {

}
