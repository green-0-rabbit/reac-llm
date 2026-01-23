# Frontend Demo Fix

This project demonstrates the recommended fixes for the AIHub frontend migration.

## Key Changes

1.  **Non-Root Nginx**: The container runs as `nginxuser` and listens on port `8080` instead of `80`.
2.  **Runtime Configuration**: Environment variables are injected at runtime using Nginx's native `envsubst` templating, instead of build-time replacements.

## How to Test

### 1. Build the App
```bash
yarn install
yarn build
```

### 2. Build the Docker Image
```bash
docker build -t frontend-fix-demo .
```

### 3. Run the Container
Pass environment variables to see them reflected in the running app.

```bash
docker run --rm -p 8080:8080 \
  -e API_URL="https://runtime-api.example.com" \
  -e SESSION_REPLAY_KEY="runtime-session-key" \
  -e PIANO_ANALYTICS_SITE_ID="runtime-site-id" \
  -e PIANO_ANALYTICS_COLLECTION_DOMAIN="runtime-collection-domain" \
  frontend-fix-demo
```

### 4. Verify
Open [http://localhost:8080](http://localhost:8080).
You should see the values passed specifically in the `docker run` command displayed on the page.

## Project Structure

*   `Dockerfile`: Updated with `USER nginxuser`, `EXPOSE 8080`, and template configuration.
*   `nginx.conf`: Listen on `8080`.
*   `config.js.template`: Template for `window.RUNTIME_CONFIG`.
*   `src/lib/env.ts`: Helper to read from `window.RUNTIME_CONFIG` or fallback to `import.meta.env`.
