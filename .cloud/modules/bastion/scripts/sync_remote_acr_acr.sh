#!/bin/bash

# Configuration
ACR_USERNAME=${1:-""}
ACR_PASSWORD=${2:-""}
ACR_FQDN=${3:-""}
IMAGES="/etc/remote_acr_images.list"

grep -v '^\s*$' $IMAGES | while read -r src; do
  echo "Image to seed: $src"
done

docker login -u $ACR_USERNAME -p $ACR_PASSWORD $ACR_FQDN
