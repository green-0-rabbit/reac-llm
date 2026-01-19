#!/bin/bash

set -euo pipefail

# Load environment if available
if [ -f /etc/sbx.env ]; then
  # shellcheck disable=SC1091
  source /etc/sbx.env
fi

# Remote ACR (source)
REMOTE_ACR_USERNAME=${1:-${REMOTE_ACR_USERNAME:-""}}
REMOTE_ACR_PASSWORD=${2:-${REMOTE_ACR_PASSWORD:-""}}
REMOTE_ACR_FQDN=${3:-${REMOTE_ACR_FQDN:-""}}

# Target ACR (destination)
ACR_NAME=${ACR_NAME:-""}
ACR_FQDN_TARGET="${ACR_NAME}.azurecr.io"

IMAGES_FILE="/etc/remote_acr_images.list"

if [ -z "$REMOTE_ACR_USERNAME" ] || [ -z "$REMOTE_ACR_PASSWORD" ] || [ -z "$REMOTE_ACR_FQDN" ]; then
  echo "Missing remote ACR credentials or FQDN."
  exit 1
fi

if [ -z "$ACR_NAME" ]; then
  echo "Missing target ACR name (ACR_NAME)."
  exit 1
fi

if [ ! -f "$IMAGES_FILE" ]; then
  echo "Images file not found: $IMAGES_FILE"
  exit 1
fi

echo "Logging into remote ACR: $REMOTE_ACR_FQDN"
docker login -u "$REMOTE_ACR_USERNAME" -p "$REMOTE_ACR_PASSWORD" "$REMOTE_ACR_FQDN"

echo "Logging into target ACR with Managed Identity: $ACR_NAME"
az login --identity --allow-no-subscriptions 1>/dev/null
if ! az acr login -n "$ACR_NAME" 1>/dev/null 2>&1; then
  TOK=$(az acr login -n "$ACR_NAME" --expose-token -o tsv --query accessToken)
  echo "$TOK" | docker login "$ACR_FQDN_TARGET" \
    --username 00000000-0000-0000-0000-000000000000 --password-stdin
fi

grep -v '^\s*$' "$IMAGES_FILE" | while read -r image; do
  echo "Seeding image: $image"
  docker pull "$REMOTE_ACR_FQDN/$image"
  docker tag "$REMOTE_ACR_FQDN/$image" "$ACR_FQDN_TARGET/$image"
  docker push "$ACR_FQDN_TARGET/$image"
done
