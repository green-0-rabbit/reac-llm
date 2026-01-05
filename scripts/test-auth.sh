#!/bin/bash

# Configuration
KEYCLOAK_URL=${1:-"http://localhost:8080"}
TODO_API_URL=${2:-"http://localhost:3000"}

REALM="api-realm"
CLIENT_ID="api-sso"
USER_EMAIL="test@domain.com"
USER_PASSWORD="userpass1234#!"
ADMIN_USER="admin"
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"admin"}

function get_token() {
    local keycloak_url=$1
    
    echo "----------------------------------------------------------------" >&2
    echo "Testing Authentication for user: ${USER_EMAIL}" >&2
    echo "Realm: ${REALM}" >&2
    echo "Client: ${CLIENT_ID}" >&2
    echo "----------------------------------------------------------------" >&2

    # 1. Get Admin Token
    echo "1. Getting Admin Token..." >&2
    ADMIN_TOKEN=$(curl -s -k -X POST "${keycloak_url}/realms/master/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=${ADMIN_USER}" \
      -d "password=${ADMIN_PASSWORD}" \
      -d "grant_type=password" \
      -d "client_id=admin-cli" | jq -r '.access_token')

    if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
      echo "Error: Failed to get admin token. Is Keycloak running?" >&2
      return 1
    fi
    echo "✔ Admin Token obtained." >&2

    # 2. Get Client UUID
    echo "2. Getting Client UUID for '${CLIENT_ID}'..." >&2
    CLIENT_UUID=$(curl -s -k -X GET "${keycloak_url}/admin/realms/${REALM}/clients?clientId=${CLIENT_ID}" \
      -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

    if [ -z "$CLIENT_UUID" ] || [ "$CLIENT_UUID" == "null" ]; then
      echo "Error: Failed to get Client UUID." >&2
      echo "Does the client '${CLIENT_ID}' exist in realm '${REALM}'?" >&2
      echo "Make sure you have applied the Terraform configuration: just kc-tf-apply" >&2
      return 1
    fi
    echo "✔ Client UUID: ${CLIENT_UUID}" >&2

    # 3. Get Client Secret
    echo "3. Getting Client Secret..." >&2
    CLIENT_SECRET=$(curl -s -k -X GET "${keycloak_url}/admin/realms/${REALM}/clients/${CLIENT_UUID}/client-secret" \
      -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.value')

    if [ -z "$CLIENT_SECRET" ] || [ "$CLIENT_SECRET" == "null" ]; then
      echo "Error: Failed to get Client Secret." >&2
      return 1
    fi
    echo "✔ Client Secret obtained." >&2

    # 4. Authenticate User
    echo "4. Authenticating User '${USER_EMAIL}'..." >&2
    USER_TOKEN_RESPONSE=$(curl -s -k -X POST "${keycloak_url}/realms/${REALM}/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=${CLIENT_ID}" \
      -d "client_secret=${CLIENT_SECRET}" \
      -d "username=${USER_EMAIL}" \
      -d "password=${USER_PASSWORD}" \
      -d "grant_type=password")

    ACCESS_TOKEN=$(echo "$USER_TOKEN_RESPONSE" | jq -r '.access_token')

    if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
      echo "Error: Failed to authenticate user." >&2
      echo "Response: $USER_TOKEN_RESPONSE" >&2
      echo "Make sure the user '${USER_EMAIL}' exists and has the correct password." >&2
      return 1
    fi

    echo "$ACCESS_TOKEN"
}

# Main execution
ACCESS_TOKEN=$(get_token "$KEYCLOAK_URL")

if [ $? -ne 0 ]; then
    echo "Authentication failed"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "✔ Successfully authenticated user!"
echo "Access Token: $ACCESS_TOKEN"
echo "----------------------------------------------------------------"

# 5. Call Protected API
echo "5. Calling protected API at $TODO_API_URL..."
API_RESPONSE=$(curl -s -k -v -X GET "$TODO_API_URL/todos" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "API Response: $API_RESPONSE"

# Check if response contains expected data
if [[ "$API_RESPONSE" == *"[]"* ]] || [[ "$API_RESPONSE" == *"[{"* ]]; then
  echo "Successfully accessed protected API"
else
  echo "Failed to access protected API"
  exit 1
fi
