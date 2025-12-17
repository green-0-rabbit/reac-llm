#!/bin/bash
mkdir -p certs

# Generate certificate with Subject Alternative Name (SAN) for IP 127.0.0.1
# This is required for Node.js to validate the certificate for an IP address
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout certs/azurite-key.pem -out certs/azurite-cert.pem \
  -subj "/CN=127.0.0.1" \
  -addext "subjectAltName=IP:127.0.0.1"

echo "Certificates generated in certs/ directory with SAN IP:127.0.0.1"

