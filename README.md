## modules architecture references

- [resources module](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
    - [container app module](https://registry.terraform.io/modules/Azure/avm-res-app-containerapp/azurerm/latest)
    - [container app job module](https://registry.terraform.io/modules/Azure/avm-res-app-job/azurerm/latest)

## devbox community image

The DevBox VM is captured as a Community Azure Compute Gallery image to avoid reprovisioning.

### current image details

- Gallery: `sbx_devbox_gallery_kag` (Community, prefix `sbckag`)
- Public gallery name: `sbckag-03a467c4-f8e6-470f-a19a-0b1f72763fd6`
- Image definition: `devbox` (publisher `kag`, offer `free`, sku `server`)
- Version: `0.0.1`
- Managed image: `devbox-infra-img-0-0-1`
- Regions: `westeurope`, `switzerlandnorth`
- EULA: `https://gist.githubusercontent.com/magic-creator-01/5ecd69e23210df2bbf97faef312ca832/raw`
- Publisher URI: `https://github.com/magic-creator-01`

### terraform usage

- Set `devbox_custom_image_id` in [.cloud/tf-infra/infra.tfvars](.cloud/tf-infra/infra.tfvars) to the image version ID:
    - `/subscriptions/<sub>/resourceGroups/sbx-main-rg/providers/Microsoft.Compute/galleries/sbx_devbox_gallery_kag/images/devbox/versions/0.0.1`
- When `custom_image_id` is set, cloud-init and the provisioning extension are skipped in [.cloud/modules/devbox/main.tf](.cloud/modules/devbox/main.tf).

### portal deployment (other tenant)

1. Create VM → Image → Community Images.
2. Search by public gallery name: `sbckag-03a467c4-f8e6-470f-a19a-0b1f72763fd6`.
3. Select image `devbox` (latest or version `0.0.1`), then deploy.

### cli deployment (other tenant)

```bash
az vm create \
    -g <rg> \
    -n <vmname> \
    --image /subscriptions/<sub>/resourceGroups/sbx-main-rg/providers/Microsoft.Compute/galleries/sbx_devbox_gallery_kag/images/devbox/versions/0.0.1 \
    --admin-username <user> \
    --admin-password <pass>
```

### verify image source

- VM control plane:
    - `az vm show -g <rg> -n <vm> --query "storageProfile.imageReference.id" -o tsv`
- OS disk source:
    - `az disk show -g <rg> -n <osDisk> --query "creationData.sourceResourceId" -o tsv`

### update flow (manual)

1. Generalize the DevBox VM and create a managed image.
2. Create a new image version in the gallery.
3. Update `devbox_custom_image_id` to the new version ID.

### add a new replication region

```bash
az sig image-version update \
    --resource-group sbx-main-rg \
    --gallery-name sbx_devbox_gallery_kag \
    --gallery-image-definition devbox \
    --gallery-image-version 0.0.1 \
    --target-regions westeurope=1 switzerlandnorth=1
```

### notes

- The DevBox VM is generalized during capture and cannot be started again.
- Community gallery requires publisher info and a public EULA URL.
- If RDP fails on a VM from this image, verify `xrdp` is installed and running on the VM.