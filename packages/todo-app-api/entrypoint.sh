#!/bin/sh
set -e

if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL not set. Generating from Managed Identity..."
  # Get the access token
  DB_TOKEN=$(node scripts/get-token.js)
  
  if [ -z "$DB_TOKEN" ]; then
    echo "Failed to get DB_TOKEN"
    exit 1
  fi
  
  # Export DATABASE_PASSWORD for MikroORM / TypeORM / ConfigService
  export DATABASE_PASSWORD="$DB_TOKEN"
  
  # Construct DATABASE_URL for Prisma
  # We need to URL encode the password for the connection string
  # Using node to encode
  ENCODED_TOKEN=$(node -e "console.log(encodeURIComponent(process.env.DATABASE_PASSWORD))")
  
  export DATABASE_URL="postgresql://${DATABASE_USERNAME}:${ENCODED_TOKEN}@${DATABASE_HOST}:${DATABASE_PORT:-5432}/${DATABASE_SCHEMA:-todo_db}?sslmode=require"
  
  echo "DATABASE_URL generated."
fi

echo "Running database migrations..."
npx prisma migrate deploy

echo "Generating Prisma client..."
npx prisma generate

echo "Starting application..."
exec node dist/main.js
