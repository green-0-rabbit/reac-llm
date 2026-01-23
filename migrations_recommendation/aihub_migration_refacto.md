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

### 3. Environment Variable Injection (NGINX Native Envsubst)
This approach leverages the official NGINX image's built-in templating capability to generate `config.js` at runtime.

**Reference Implementation:**
A working example of this implementation (Proof of Concept) is available in this workspace:
*   **Source Code**: [packages/frontend-demo-fix/src](../packages/frontend-demo-fix/src) (Contains `env.ts` helper and usage examples)
*   **Dockerfile**: [packages/frontend-demo-fix/Dockerfile](../packages/frontend-demo-fix/Dockerfile) (Updated with Envsubst and non-root user)
*   **Terraform Module**: See `module "frontend_aihub_fix"` in [.cloud/examples/aihub/aca.tf](../.cloud/examples/aihub/aca.tf)

**Step 1: Create Template File**
Create `config.js.template` in the root of your project (alongside `Dockerfile` and `nginx.conf`):
```javascript
window.RUNTIME_CONFIG = {
  API_URL: "${API_URL}",
  SESSION_REPLAY_KEY: "${SESSION_REPLAY_KEY}",
  PIANO_ANALYTICS_SITE_ID: "${PIANO_ANALYTICS_SITE_ID}",
  PIANO_ANALYTICS_COLLECTION_DOMAIN: "${PIANO_ANALYTICS_COLLECTION_DOMAIN}"
};
```
*Note: These correspond to the VITE variables used in your code.*

**Step 2: Update HTML**
In `index.html` (project root), add the script tag inside `<head>` before your main script:

```html
<head>
    <!-- ... existing tags ... -->
    <script src="/config.js"></script>
    <script type="module" src="/src/main.tsx"></script>
</head>
```

**Step 3: Create Runtime Config Configuration Helper**
Create `src/lib/env.ts` to centralize environment variable access:
```typescript
interface RuntimeConfig {
  API_URL?: string;
  SESSION_REPLAY_KEY?: string;
  PIANO_ANALYTICS_SITE_ID?: string;
  PIANO_ANALYTICS_COLLECTION_DOMAIN?: string;
}

export const getEnv = (key: keyof RuntimeConfig) => {
  const runtime = (window as any).RUNTIME_CONFIG as RuntimeConfig;
  return runtime?.[key] || import.meta.env[`VITE_${key}`];
};
```

**Step 4: Update Application Code**
Replace `import.meta.env` usages in your application files:

*   **`src/lib/api-client.ts`**:
    ```typescript
    import { getEnv } from './env';
    // ...
    baseURL: getEnv('API_URL'),
    ```
*   **`src/lib/piano-analytics.ts`**:
    ```typescript
    import { getEnv } from './env';
    const PIANO_ANALYTICS_SITE_ID = getEnv('PIANO_ANALYTICS_SITE_ID');
    const PIANO_ANALYTICS_COLLECTION_DOMAIN = getEnv('PIANO_ANALYTICS_COLLECTION_DOMAIN');
    ```
*   **`src/app/routes/login/page.tsx`**:
    ```typescript
    import { getEnv } from '@/lib/env'; // assuming @ alias
    window.location.href = `${getEnv('API_URL')}/auth/login`;
    ```
*   **`src/main.tsx`**:
    ```typescript
    import { getEnv } from './lib/env';
    // ...
    key: getEnv('SESSION_REPLAY_KEY'),
    ```

**Step 5: Update Dockerfile**
Update `Dockerfile` to copy the template and set the output directory:

```dockerfile
FROM nginx:stable-alpine

RUN addgroup -S nginxgroup \
 && adduser -S nginxuser -G nginxgroup \
 && mkdir -p /run \
 && chown -R nginxuser:nginxgroup /run \
 && chown -R nginxuser:nginxgroup /usr/share/nginx/html \
 && chown -R nginxuser:nginxgroup /var/cache/nginx

COPY --chown=nginxuser:nginxgroup dist/ /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# --- NEW: Copy template for runtime config ---
COPY config.js.template /etc/nginx/templates/config.js.template
ENV NGINX_ENVSUBST_OUTPUT_DIR=/usr/share/nginx/html
# ---------------------------------------------

EXPOSE 8080
USER nginxuser
CMD ["nginx", "-g", "daemon off;"]
```

**Step 6: Update Terraform**
In `aca.tf`, pass standard environment variables.
```terraform
        env = [
          {
            name  = "API_URL"
            value = "https://${local.backend_aihub_fqdn}"
          },
          {
            name  = "SESSION_REPLAY_KEY"
            value = var.session_replay_key
          },
          {
            name  = "PIANO_ANALYTICS_SITE_ID"
            value = var.piano_analytics_site_id
          },
          {
            name  = "PIANO_ANALYTICS_COLLECTION_DOMAIN"
            value = var.piano_analytics_collection_domain
          }
        ]
```

## Summary of Benefits
*   **Security**: Runs as non-root without hacks.
*   **Simplicity**: Removes complex shell scripts from Terraform `command`.
*   **Standardization**: Aligns with standard ACA ingress patterns.
*   **Portability**: The same Docker image can be deployed to Dev, Staging, and Prop without rebuilding, just by changing environment variables.
