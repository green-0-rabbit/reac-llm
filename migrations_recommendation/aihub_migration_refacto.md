# AIHub Migration Refactoring & Recommendations

## Context
During the migration of the AIHub application to Azure Container Apps (ACA), specifically the `ai-hub-frontend`, we encountered configuration issues related to container privileges and hardcoded domain values. 

The current deployment in `.cloud/examples/aihub/aca.tf` uses a workaround involving a complex `command` override to patch Nginx configurations at runtime. This document outlines the recommended changes to the source code (Dockerfile and Nginx config) to simplify deployment and adhere to best practices.

## Issues Identified

### 1. Port Binding Permission Denied
The frontend container currently attempts to bind to port `80`.
```log
2026/01/20 02:50:13 [emerg] 1#1: bind() to 0.0.0.0:80 failed (13: Permission denied)
```
**Cause:** The Dockerfile specifies `USER nginxuser` (non-root). Non-privileged users cannot bind to ports below 1024.

### 2. Hardcoded Domain Values
The application source code or build process injects a hardcoded API domain (`api-aihub.lab-iwm.com`) at build time via the CI/CD pipeline. The `VITE_API_URL` is baked into the static assets.

**Source (azure-pipelines.yml):**
```yml
          - task: Bash@3
            displayName: "Create .env file"
            inputs:
              targetType: inline
              script: |
                echo "VITE_API_URL=$(API_URL)" > $(Build.SourcesDirectory)/.env
                echo "VITE_SESSION_REPLAY_KEY=$(SESSION_REPLAY_KEY)" >> $(Build.SourcesDirectory)/.env
                echo "VITE_PIANO_ANALYTICS_SITE_ID=$(PIANO_ANALYTICS_SITE_ID)" >> $(Build.SourcesDirectory)/.env
                echo "VITE_PIANO_ANALYTICS_COLLECTION_DOMAIN=$(PIANO_ANALYTICS_COLLECTION_DOMAIN)" >> $(Build.SourcesDirectory)/.env
```

**Cause:** Vite replaces `import.meta.env.VITE_API_URL` with the literal string value during `pnpm run build`. This makes the Docker image environment-dependent.
**Current Workaround:** The Terraform configuration currently uses `sed` to replace this value at runtime in a temporary directory.

## Recommendations

### 1. Refactor Dockerfile & Nginx Configuration
Move away from privileged ports to allow the container to run seamlessly as a non-root user.

**Update `nginx.conf`**:
Change the listening port from `80` to `8080`.
```nginx
server {
    listen 8080;
    listen [::]:8080;
    # ... rest of configuration
}
```

**Update `Dockerfile`**:
Expose port 8080 and ensure file permissions are handled cleanly.
```dockerfile
FROM nginx:stable-alpine

RUN addgroup -S nginxgroup \
 && adduser -S nginxuser -G nginxgroup

# Copy with ownership to avoid recursive chown layers
COPY --chown=nginxuser:nginxgroup dist/ /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
USER nginxuser
CMD ["nginx", "-g", "daemon off;"]
```

### 2. Update Infrastructure Configuration (Terraform)
Once the container image is updated to listen on port 8080 natively, the Terraform configuration can be simplified significantly.

**File:** [.cloud/examples/aihub/aca.tf](../.cloud/examples/aihub/aca.tf)

**Changes:**
1.  **Ingress**: Ensure `target_port` is set to `8080`.
2.  **Container Command**: Remove the complex `command` override that patches files in `/tmp`. The environment-specific variables should ideally be handled via build-time arguments or runtime environment variables injection supported by the application code, rather than `sed` replacements.

**ACA Ingress Configuration Reference:**
Azure Container Apps supports exposing HTTP/HTTPS on standard ports (80/443) externally while targeting a custom port (e.g., 8080) on the container.
*   [ACA Ingress Documentation](https://learn.microsoft.com/en-us/azure/container-apps/ingress-how-to)

### 3. Environment Variable Injection (Long-term)
**Problem:** `VITE_` variables are replaced at build time, baking environment-specific configurations into the artifacts.
**Solution:** Implement the "Runtime Configuration" pattern.

**Step 1: Container Entrypoint Script**
Add a script to generate a `config.js` file from environment variables at container startup.
Create a file `/docker-entrypoint.d/40-generate-config.sh` (or add to your custom entrypoint):

```bash
#!/bin/sh
cat <<EOF > /usr/share/nginx/html/config.js
window.RUNTIME_CONFIG = {
  API_URL: "${API_URL:-https://default-api.com}",
  SESSION_REPLAY_KEY: "${SESSION_REPLAY_KEY}",
  PIANO_ANALYTICS_SITE_ID: "${PIANO_ANALYTICS_SITE_ID}",
  PIANO_ANALYTICS_COLLECTION_DOMAIN: "${PIANO_ANALYTICS_COLLECTION_DOMAIN}"
};
EOF
```

**Step 2: Update HTML**
Include this script in your `index.html` (in the `public` folder of your React project) so it loads before your app bundle.

```html
<head>
  <!-- ... -->
  <script src="/config.js"></script>
</head>
```

**Step 3: Update React Code**
Create a utility function to access these variables, preferring the runtime config over the build-time env vars.

```typescript
// src/config.ts
export const getEnv = (key: string) => {
  // @ts-ignore
  const runtimeValue = window.RUNTIME_CONFIG?.[key];
  const buildTimeValue = import.meta.env[`VITE_${key}`];
  return runtimeValue || buildTimeValue;
};

// Usage
const apiUrl = getEnv('API_URL');
```

**Step 4: Update Terraform**
In `aca.tf`, you can now pass standard environment variables like `API_URL` instead of relying on `sed` hacks.

```terraform
        env = [
          {
            name  = "API_URL"
            value = "https://${local.backend_aihub_fqdn}"
          },
          # ...
        ]
```

## Summary of Benefits
*   **Security**: Runs as non-root without hacks.
*   **Simplicity**: Removes complex shell scripts from Terraform `command`.
*   **Standardization**: Aligns with standard ACA ingress patterns.
*   **Portability**: The same Docker image can be deployed to Dev, Staging, and Prop without rebuilding, just by changing environment variables.
