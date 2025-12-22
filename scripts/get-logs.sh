#!/bin/bash
set -e

# Load environment variables
# source .env

# Get the resource group name
RESOURCE_GROUP=$(az group list --query "[?tags.env == 'dev'].name" -o tsv)

# Get the container app name
CONTAINER_APP_NAME=$(az containerapp list -g $RESOURCE_GROUP --query "[?contains(name, 'containerappdemo')].name" -o tsv)

echo "Fetching logs for container app: $CONTAINER_APP_NAME in resource group: $RESOURCE_GROUP"

# Fetch logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --follow false \
  --tail 50
