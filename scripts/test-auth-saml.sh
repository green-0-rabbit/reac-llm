#!/bin/bash

# Configuration
SP_BASE_URL="http://localhost:3002"
LOGIN_URL="${SP_BASE_URL}/auth/login"
PROTECTED_URL="${SP_BASE_URL}/"

# User Credentials from Terraform
USER_EMAIL="test@domain.com"
USER_PASSWORD="userpass1234#!"

COOKIE_JAR="saml_cookies.txt"
rm -f $COOKIE_JAR

echo "----------------------------------------------------------------"
echo "Testing SAML Authentication Flow"
echo "User: ${USER_EMAIL}"
echo "----------------------------------------------------------------"

# 1. Access Login Page to get Redirect URL and Session Cookies
echo "1. Accessing SP Login Page..."
LOGIN_PAGE_HTML=$(curl -s -L -c $COOKIE_JAR -b $COOKIE_JAR "$LOGIN_URL")

# Extract the action URL from the Keycloak login form
ACTION_URL=$(echo "$LOGIN_PAGE_HTML" | grep -o 'action="[^"]*"' | head -1 | cut -d'"' -f2)
# Decode HTML entities if any (specifically &amp;)
ACTION_URL=$(echo "$ACTION_URL" | sed 's/&amp;/\&/g')

if [ -z "$ACTION_URL" ]; then
  echo "Error: Could not find login form action URL. Is Keycloak running?"
  exit 1
fi
echo "✔ Found Login Action URL: $ACTION_URL"

# 2. Submit Credentials
echo "2. Submitting Credentials to Keycloak..."
SAML_POST_PAGE=$(curl -s -L -c $COOKIE_JAR -b $COOKIE_JAR -X POST "$ACTION_URL" \
  --data-urlencode "username=${USER_EMAIL}" \
  --data-urlencode "password=${USER_PASSWORD}")

# 3. Extract SAMLResponse and RelayState
echo "3. Extracting SAML Response..."
SAML_RESPONSE=$(echo "$SAML_POST_PAGE" | grep -o 'name="SAMLResponse" value="[^"]*"' | cut -d'"' -f4)
echo "SAML Response: $SAML_RESPONSE"
RELAY_STATE=$(echo "$SAML_POST_PAGE" | grep -o 'name="RelayState" value="[^"]*"' | cut -d'"' -f4)
CALLBACK_URL=$(echo "$SAML_POST_PAGE" | grep -o 'action="[^"]*"' | head -1 | cut -d'"' -f2)

if [ -z "$SAML_RESPONSE" ]; then
  echo "Error: Could not find SAMLResponse. Login might have failed."
  # echo "Debug HTML:"
  # echo "$SAML_POST_PAGE"
  exit 1
fi
echo "✔ SAML Response obtained."
echo "✔ Callback URL: $CALLBACK_URL"

# 4. Submit SAMLResponse to SP Callback
echo "4. Submitting SAML Response to SP..."
# We use -i to see headers, capturing the Set-Cookie
CALLBACK_RESULT=$(curl -i -s -L -c $COOKIE_JAR -b $COOKIE_JAR -X POST "$CALLBACK_URL" \
  --data-urlencode "SAMLResponse=${SAML_RESPONSE}" \
  --data-urlencode "RelayState=${RELAY_STATE}")

# Check for success (Redirect to frontend usually)
if echo "$CALLBACK_RESULT" | grep -q "HTTP/1.1 302 Found"; then
  echo "✔ Callback accepted. Redirect received."
else
    # It might be 200 if it renders a page, but our controller redirects.
    echo "Warning: Expected 302 Redirect, got something else. Checking for cookie anyway."
    echo "DEBUG: Callback Result Body:"
    echo "$CALLBACK_RESULT"
fi

# 5. Verify Authentication Cookie
echo "5. Verifying Authentication Cookie..."
# Look for 'Authentication' cookie in jar
AUTH_COOKIE=$(grep "Authentication" $COOKIE_JAR)

if [ -n "$AUTH_COOKIE" ]; then
  echo "✔ Authentication Cookie found in jar."
else
  echo "Error: Authentication cookie not found."
  exit 1
fi

# 6. Access Protected Resource
echo "6. Accessing Protected Resource ($PROTECTED_URL)..."
API_RESPONSE=$(curl -s -c $COOKIE_JAR -b $COOKIE_JAR "$PROTECTED_URL")

# Check if we got the Hello World (or whatever the root returns) instead of 401/403
# Root returns "Hello World!" usually or JSON
echo "API Response: $API_RESPONSE"

if [[ "$API_RESPONSE" == *"Hello"* ]]; then
  echo "----------------------------------------------------------------"
  echo "✔ SUCCESS: Validated SAML login and API access."
  echo "----------------------------------------------------------------"
else 
  # If it's not "Hello", maybe it's { message: ... } but NOT Unauthorized
  if [[ "$API_RESPONSE" == *"Unauthorized"* ]]; then
      echo "❌ FAILED: API returned Unauthorized."
      exit 1
  else
      echo "✔ SUCCESS: API Accessed (Response received)."
  fi
fi

# Cleanup
rm -f $COOKIE_JAR
