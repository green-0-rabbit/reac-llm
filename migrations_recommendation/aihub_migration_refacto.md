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

### 4. Backend Service Connection Security

### Problem: Security Risks with Static Keys
The current backend implementation relies on static keys and connection strings to authenticate with Azure services. This practice presents several security risks and operational challenges:

*   **Azure Storage**: Relies on `AZURE_STORAGE_CONNECTION_STRING`, which often contains the broad-access account key.
*   **AI Foundry / Azure OpenAI**: Uses a static `API_KEY` injected via environment variables.
*   **PostgreSQL**: Uses a password embedded in the `DATABASE_URL`.

**Risks:**
*   **Credential Leakage**: Keys accidentally committed to source control or exposed in logs.
*   **Rotation Complexity**: Rotating keys requires restarting services and updating configuration across multiple environments.
*   **Lack of Granularity**: Keys often provide broad access permissions rather than least-privileged access.

### Solution: Managed Identity (Keyless Authentication)
We strongly recommend transitioning to **Microsoft Entra ID (formerly Azure AD) Managed Identities**. This approach allows the application to authenticate using the identity assigned to the Azure Container App, eliminating the need to manage secrets within the application code or configuration.

#### Implementation Reference
We have successfully implemented and validated this pattern in the `todo-app-api` package.

**1. Azure Storage Implementation (Keyless)**
*   **Codebase**: [packages/todo-app-api/src/storage/storage.service.ts](../packages/todo-app-api/src/storage/storage.service.ts)
*   **Mechanism**: The service uses `DefaultAzureCredential` which automatically detects the managed identity environment.
*   **Configuration**: Only the Service URI is required.
    ```typescript
    // src/storage/storage.service.ts
    this.blobServiceClient = new BlobServiceClient(
      serviceUri,
      new DefaultAzureCredential(),
    );
    ```

**2. Azure AI Foundry / OpenAI Implementation (Keyless)**
*   **Codebase**: [packages/todo-app-api/src/ai/ai.client.ts](../packages/todo-app-api/src/ai/ai.client.ts)
*   **Mechanism**: The client explicitly requests an Entra ID token for the Cognitive Services scope.
*   **Configuration**: Only the Endpoint URL and Model Deployment name are required.
    ```typescript
    // src/ai/ai.client.ts
    const tokenResponse = await this.credential.getToken(
      'https://cognitiveservices.azure.com/.default',
    );
    // Use token in Authorization header: `Bearer ${tokenResponse.token}`
    ```

**3. Azure PostgreSQL Flexible Server Implementation (Keyless)**
*   **Codebase**: `entrypoint.sh` and `scripts/get-token.js` in `todo-app-api`
*   **Mechanism**: The application requests an access token for the OSS RDBMS scope (`https://ossrdbms-aad.database.windows.net/.default`) using the User Assigned Identity.
*   **Configuration**:
    *   **Postgres Admin**: The User Assigned Identity (`acami-dev`) is set as the `active_directory_administrator` using its **name** as the principal.
    *   **Connection String**: The `DATABASE_URL` is constructed dynamically at startup using the identity's name as the username and the fetched token as the password.
    *   **Terraform**: The `DATABASE_USERNAME` environment variable is set to the **name** of the identity (e.g., `acami-dev`), NOT the Client ID.
    ```bash
    # entrypoint.sh logic
    export DATABASE_URL="postgresql://${DATABASE_USERNAME}:${ENCODED_TOKEN}@${DATABASE_HOST}:5432/${DATABASE_SCHEMA}?sslmode=require"
    ```

**4. Infrastructure Configuration**
*   **File**: [.cloud/examples/aihub/aca.tf](../.cloud/examples/aihub/aca.tf)
*   **Setup**:
    *   **Identity**: A User Assigned Identity (`acami-dev`) is assigned to the Container App.
    *   **RBAC**: Role Assignments are created to grant specific permissions to that identity:
        *   `Storage Blob Data Contributor` on the Storage Account.
        *   `Cognitive Services OpenAI User` on the AI Foundry account.
    *   **Postgres**: The identity is added as an AD Administrator.
    *   **Env Vars**: No secrets are passed to the container, only resource Identifiers (URIs) and the Identity Name.

### 5. Database Schema & Query Compatibility (No Unaccent Extension)

### Problem: Unsupported Extension
The existing codebase utilizes the PostgreSQL \`unaccent\` extension for accent-insensitive search queries. However, enabling extensions often requires superuser privileges or specific allow-lists which might not be available or configured in the target Azure Database for PostgreSQL Flexible Server environment.

### Solution: Node-side Filtering & Optimized SQL
**Note: This is a temporary workaround until the `unaccent` extension is validated and enabled on the target environment.**

Instead of relying on the database extension, we recommend fetching relevant records using an optimized SQL query and performing the accent-insensitive filtering within the Node.js application layer.

**Refactoring Strategy:**
1.  **Optimize SQL**: Replace expensive \`GROUP BY\` + \`DISTINCT\` \`json_agg\` patterns with \`LATERAL\` subqueries for better performance and cleaner syntax.
2.  **Remove unaccent**: Drop the \`WHERE unaccent(...)\` clause from the SQL.
3.  **In-Memory Search**: Implement a simple helper to normalize strings (fold accents) and filter the result set in JavaScript/TypeScript.

**Implementation Example:**

\`\`\`typescript
// Helper function for accent folding (if not already available)
function foldForSearch(str: string): string {
  return str.normalize("NFD").replace(/[\\u0300-\\u036f]/g, "").toLowerCase();
}

// Repository Method Implementation
async findAll(
  language: string = this.defaultLanguage,
  latest: boolean = this.defaultLatest,
  search?: string,
  category?: string,
  businessLine?: string,
): Promise<any> {
  const take = latest ? this.defaultTake : undefined;

  const tagIds: string[] = [];
  if (category) tagIds.push(category);
  if (businessLine) tagIds.push(businessLine);

  // OPTIMIZED QUERY: Uses LATERAL joins instead of GROUP BY + DISTINCT
  const query = \`
    SELECT
      u.*,
      COALESCE(t.translations, '[]') AS translations,
      COALESCE(kb.keyBenefits, '[]') AS "keyBenefits",
      COALESCE(tags.tags, '[]') AS tags
    FROM "Usecase" u

    LEFT JOIN LATERAL (
      SELECT json_agg(t.*) AS translations
      FROM "UsecaseTranslation" t
      WHERE t."usecaseId" = u.id AND t.language = $1
    ) t ON true

    LEFT JOIN LATERAL (
      SELECT json_agg(kb.*) AS keyBenefits
      FROM "UsecaseKeyBenefit" kb
      WHERE kb."usecaseId" = u.id AND kb.language = $1
    ) kb ON true

    LEFT JOIN LATERAL (
      SELECT json_agg(
        jsonb_build_object(
          'id', tag.id,
          'type', tag.type,
          'label', tagt.label
        )
      ) AS tags
      FROM "UsecaseTags" ut
      JOIN "Tag" tag ON tag.id = ut."tagId"
      LEFT JOIN "TagTranslation" tagt
        ON tagt."tagId" = tag.id AND tagt.language = $1
      WHERE ut."usecaseId" = u.id
    ) tags ON true

    WHERE (
      $2::uuid[] IS NULL
      OR EXISTS (
        SELECT 1
        FROM "UsecaseTags" ut2
        WHERE ut2."usecaseId" = u.id
          AND ut2."tagId" = ANY($2::uuid[])
      )
    )
    ORDER BY u."createdAt" DESC
    \${take ? \`LIMIT \${take}\` : ''}
  \`;

  const params = [language, tagIds.length ? tagIds : null];

  const rows = (await this.prismaService.$queryRawUnsafe(query, ...params)) as any[];

  // In-memory “unaccent ILIKE %search%”
  if (!search?.trim()) return rows;

  const needle = foldForSearch(search.trim());

  return rows.filter((u) => {
    const tr = Array.isArray(u.translations) ? u.translations[0] : undefined;

    const haystack = foldForSearch(
      [
        tr?.title,
        tr?.shortDescription,
        tr?.fullDescription,
        // optional: tag labels too
        ...(Array.isArray(u.tags) ? u.tags.map((x: any) => x?.label) : []),
      ]
        .filter(Boolean)
        .join(" ")
    );

    return haystack.includes(needle);
  });
}
\`\`\`

**Why this is better:**
*   **Portability**: Removes dependency on database specific extensions (\`unaccent\`).
*   **Performance**: \`LATERAL\` joins can be more efficient than pulling the whole table or using complex aggregations, while still pushing the heavy lifting of joining and initial filtering to the DB.
*   **Safety**: Avoiding \`unaccent\` ensures the application runs on restrictive database environments.

## Summary of Benefits
*   **Security**: Runs as non-root without hacks.
*   **Simplicity**: Removes complex shell scripts from Terraform `command`.
*   **Standardization**: Aligns with standard ACA ingress patterns.
*   **Portability**: The same Docker image can be deployed to Dev, Staging, and Prop without rebuilding, just by changing environment variables.
