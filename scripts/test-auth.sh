#!/bin/bash

# Configuration
KEYCLOAK_URL="http://localhost:8080"
REALM="api-realm"
CLIENT_ID="api-sso"
USER_EMAIL="test@domain.com"
USER_PASSWORD="userpass1234#!"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "----------------------------------------------------------------"
echo "Testing Authentication for user: ${USER_EMAIL}"
echo "Realm: ${REALM}"
echo "Client: ${CLIENT_ID}"
echo "----------------------------------------------------------------"

# 1. Get Admin Token
echo "1. Getting Admin Token..."
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
  echo "Error: Failed to get admin token. Is Keycloak running?"
  exit 1
fi
echo "✔ Admin Token obtained."

# 2. Get Client UUID
echo "2. Getting Client UUID for '${CLIENT_ID}'..."
CLIENT_UUID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=${CLIENT_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

if [ -z "$CLIENT_UUID" ] || [ "$CLIENT_UUID" == "null" ]; then
  echo "Error: Failed to get Client UUID."
  echo "Does the client '${CLIENT_ID}' exist in realm '${REALM}'?"
  echo "Make sure you have applied the Terraform configuration: just kc-tf-apply"
  exit 1
fi
echo "✔ Client UUID: ${CLIENT_UUID}"

# 3. Get Client Secret
echo "3. Getting Client Secret..."
CLIENT_SECRET=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}/client-secret" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.value')

if [ -z "$CLIENT_SECRET" ] || [ "$CLIENT_SECRET" == "null" ]; then
  echo "Error: Failed to get Client Secret."
  exit 1
fi
echo "✔ Client Secret obtained."

# 4. Authenticate User
echo "4. Authenticating User '${USER_EMAIL}'..."
USER_TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "username=${USER_EMAIL}" \
  -d "password=${USER_PASSWORD}" \
  -d "grant_type=password")

ACCESS_TOKEN=$(echo "$USER_TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
  echo "Error: Failed to authenticate user."
  echo "Response: $USER_TOKEN_RESPONSE"
  echo "Make sure the user '${USER_EMAIL}' exists and has the correct password."
  exit 1
fi

echo "----------------------------------------------------------------"
echo "✔ Successfully authenticated user!"
echo "Access Token (truncated): ${ACCESS_TOKEN:0:50}..."
echo "----------------------------------------------------------------"
