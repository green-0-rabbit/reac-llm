# devbox_windows

Terraform module that provisions a Windows 11 development VM on Azure with optional WSL 2 toolchain bootstrapping and Azure Bastion (Developer SKU) access.

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Azure Resource Group                            │
│                                                  │
│  ┌────────────┐   ┌─────────────────────────┐    │
│  │  NIC       │──▶│  Windows 11 VM          │    │
│  │  (+ PIP?)  │   │  ┌───────────────────┐  │    │
│  └────────────┘   │  │ OS Disk           │  │    │
│                   │  └───────────────────┘  │    │
│                   │  ┌───────────────────┐  │    │
│                   │  │ Data Disk (100 GB)│  │    │
│                   │  └───────────────────┘  │    │
│                   │  ┌───────────────────┐  │    │
│                   │  │ CustomScript Ext  │  │    │
│                   │  │ (WSL bootstrap)   │  │    │
│                   │  └───────────────────┘  │    │
│                   └─────────────────────────┘    │
│                                                  │
│  ┌────────────────────────┐                      │
│  │  Bastion (Developer)   │                      │
│  └────────────────────────┘                      │
└──────────────────────────────────────────────────┘
```

## Features

- **Windows 11 VM** — defaults to `win11-25h2-pro` marketplace image, or use a custom gallery image via `custom_image_id`.
- **Data disk** — configurable size/SKU, attached at LUN 0.
- **Azure Bastion (Developer)** — optional, provides browser-based RDP without a public IP on the VM.
- **WSL 2 bootstrap** — optional two-phase automated setup that installs VS Code, Ubuntu, and a full dev toolchain.
- **Managed identity** — optional system-assigned identity for passwordless access to Azure services.

## WSL Bootstrap (two-phase)

When `enable_wsl_bootstrap = true`, a `CustomScriptExtension` runs a two-phase provisioning flow:

### Phase 1 — runs as SYSTEM at VM creation

| Step | Action |
|------|--------|
| 1 | Install VS Code (machine-wide via `winget`) |
| 2 | Enable `Microsoft-Windows-Subsystem-Linux` and `VirtualMachinePlatform` Windows features |
| 3 | Write `C:\bwsl\tc.sh` (toolchain script) and `C:\bwsl\p2.ps1` (Phase 2 script) to disk |
| 4 | Register a scheduled task (`BWP2`) to run Phase 2 at first admin logon |
| 5 | Reboot the VM (activates the WSL kernel) |

### Phase 2 — runs as the interactive user at first logon

| Step | Action |
|------|--------|
| 1 | Set WSL default version to 2 |
| 2 | Install Ubuntu distro (web-download with fallback) |
| 3 | Execute `tc.sh` inside WSL Ubuntu as root |
| 4 | On success: unregister the scheduled task and clean up `C:\bwsl\` |

### Toolchain installed in WSL Ubuntu

| Tool | Source |
|------|--------|
| Terraform | HashiCorp APT repository |
| Docker CE | Docker official APT repository |
| Docker Compose | Docker Compose plugin |
| Node.js (latest) | NVM |
| Yarn (stable) | Corepack |
| Azure CLI | Microsoft install script |
| just | just.systems install script |

### Observability

| Log file | Content |
|----------|---------|
| `C:\WindowsAzure\Logs\bwsl.log` | Phase 1 output |
| `C:\WindowsAzure\Logs\bwsl2.log` | Phase 2 output |

### Manual toolchain install

If Phase 2 doesn't complete automatically, run from inside WSL:

```bash
sudo bash /mnt/c/bwsl/tc.sh
```

## Usage

```hcl
module "devbox_windows" {
  source = "../modules/devbox_windows"

  project             = "my-project"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.devbox.id
  admin_username      = "bastionadmin"
  admin_password      = var.admin_password

  # Optional: use a custom gallery image instead of marketplace
  # custom_image_id = "/subscriptions/.../versions/0.0.3"

  enable_wsl_bootstrap = true
  enable_bastion_host  = true
  virtual_network_id   = azurerm_virtual_network.vnet.id

  tags = { environment = "dev" }
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Project name for tagging. |
| `resource_group_name` | `string` | — | Resource group for all resources. |
| `location` | `string` | — | Azure region. |
| `subnet_id` | `string` | — | Subnet ID for the VM NIC. |
| `vm_name` | `string` | `"vm-windevbox"` | VM resource name. |
| `nic_name` | `string` | `null` | NIC name (defaults to `<vm_name>-nic`). |
| `osdisk_name` | `string` | `null` | OS disk name (defaults to `<vm_name>-osdisk`). |
| `datadisk_name` | `string` | `null` | Data disk name (defaults to `<vm_name>-data`). |
| `vm_size` | `string` | `"Standard_D2s_v3"` | VM size. |
| `admin_username` | `string` | `"devadmin"` | Local admin username. |
| `admin_password` | `string` | — | Local admin password (sensitive). |
| `os_disk_sku` | `string` | `"Standard_LRS"` | OS disk storage SKU. |
| `data_disk_sku` | `string` | `"Standard_LRS"` | Data disk storage SKU. |
| `data_disk_size_gb` | `number` | `100` | Data disk size in GB. |
| `image_publisher` | `string` | `"MicrosoftWindowsDesktop"` | Marketplace image publisher. |
| `image_offer` | `string` | `"windows-11"` | Marketplace image offer. |
| `image_sku` | `string` | `"win11-25h2-pro"` | Marketplace image SKU. |
| `custom_image_id` | `string` | `null` | Custom image ID (overrides marketplace). |
| `tags` | `map(string)` | `{}` | Resource tags. |
| `enable_managed_identity` | `bool` | `true` | Enable system-assigned managed identity. |
| `enable_public_ip` | `bool` | `false` | Attach a public IP to the NIC. |
| `enable_wsl_bootstrap` | `bool` | `false` | Run WSL + toolchain bootstrap on first boot. |
| `enable_bastion_host` | `bool` | `true` | Create an Azure Bastion (Developer SKU). |
| `virtual_network_id` | `string` | `null` | VNet ID (required when Bastion is enabled). |
| `bastion_name` | `string` | `null` | Bastion host name override. |

## Outputs

| Name | Description |
|------|-------------|
| `private_ip` | Private IP of the VM. |
| `vm_id` | Resource ID of the VM. |
| `principal_id` | System-assigned managed identity principal ID (or `null`). |
| `public_ip` | Public IP address (or `null`). |
| `bastion_name` | Bastion host name (or `null`). |
| `bastion_public_ip` | Always `null` (Developer SKU has no public IP). |

## File structure

```
devbox_windows/
├── bastion.tf          # Azure Bastion (Developer SKU)
├── main.tf             # VM, disks, CustomScript extension
├── network.tf          # NIC + optional public IP
├── outputs.tf          # Module outputs
├── variables.tf        # Input variables
├── versions.tf         # Provider requirements (azurerm >= 4.50)
├── README.md           # This file
└── scripts/
    └── bootstrap-wsl.ps1   # Two-phase WSL bootstrap script
```

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.1.0 |
| azurerm | >= 4.50.0 |
