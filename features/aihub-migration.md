#+ AIHub Migration Plan (Draft)

> Purpose: Track progress of the Copilot agent while migrating AIHub (frontend, backend, and Keycloak SSO) from a source Azure tenant to the target environment.

## Chapter 1 — Scope & Objectives

### 1.1 Goals
- Migrate the full AIHub application stack (frontend + backend).
- Recreate or migrate all SSO Keycloak dependencies (realms, clients, roles, users, certs, secrets).
- Maintain parity with current production behavior and security controls.

### 1.2 Out of Scope (for this phase)
- Feature changes unrelated to migration.
- Large refactors or tech stack upgrades.
- Non-essential analytics or monitoring improvements (unless required for parity).

### 1.3 Success Criteria
- The migrated stack is reachable, stable, and functionally equivalent.
- SSO login works end‑to‑end and aligns with existing access rules.
- Data paths, secrets, and environment configuration are validated and documented.
- A rollback path exists and has been tested (at least for core services).

### 1.4 Tracking & Status
| Area | Status | Notes |
| --- | --- | --- |
| Inventory current Azure resources | Not started | |
| Frontend migration | Not started | |
| Backend migration | Not started | |
| Keycloak SSO migration | Not started | |
| Networking + DNS | Not started | |
| Secrets & configuration | Not started | |
| Validation & smoke tests | Not started | |

---

## Chapter 2 — Current State Discovery (Deep Dive)

> This chapter captures the **source** tenant’s real setup before migration. Populate each section with concrete details and evidence (screenshots, CLI outputs, configs).

### 2.1 Application Overview
- **Product name:** AIHub
- **Environments:** preprod, prod (release-driven); dev via variable groups
- **Primary URLs:**
	- Frontend: Front Door entrypoint (see [Front Door config](https://dev.azure.com/lab-inno/AI%20Portal/_workitems/edit/2435))
	- Backend/API: App Service (Front + Back) module (see [app module](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/app/main.tf&version=GBmain&line=9&lineEnd=10&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents))
	- Auth/SSO: Keycloak app service (see [Keycloak App Service](https://portal.azure.com/#@labinno.onmicrosoft.com/resource/subscriptions/e4d4b19f-5566-418e-8597-040de3f1751b/resourceGroups/keycloak-inno-lab-rg/providers/Microsoft.Web/sites/Keycloak-inno-lab/appServices))
	  - Deployed instance: https://keycloak.lab-iwm.com/
- **Project analysis:**  

    Full‑stack app. **Frontend (React)** is not directly linked to SSO but has auth-related implementation: [useAuth hook](https://dev.azure.com/lab-inno/AI%20Portal/_git/frontend?path=%2Fsrc%2Fhooks%2Fuse-auth.ts&_a=contents&version=GBdev), [protected route wrapper](https://dev.azure.com/lab-inno/AI%20Portal/_git/frontend?path=%2Fsrc%2Fcomponents%2Frouting%2Fprotected-route.tsx&_a=contents&version=GBdev), and [router](https://dev.azure.com/lab-inno/AI%20Portal/_git/frontend?path=%2Fsrc%2Fapp%2Frouter.tsx&_a=contents&version=GBdev). **Backend (NestJS)** uses Passport SAML. Integrations: Postgres, Keycloak (SAML clients aihub-prod/aihub-preprod), Storage account (assets), Front Door. Provisioning via Terraform in dedicated infra repo; releases drive preprod/prod; DB migrations happen in Dockerfile and `entrypoint.sh` before `main.js`.
- **Owners/Contacts:** TBD
- **Critical SLAs/availability requirements:** TBD

### 2.2 Frontend (Source)
- **Hosting model:** App Service (shared “app” module) behind Front Door
- **Runtime & build:** React; build triggered by Azure DevOps release pipeline
- **Configuration:** variable groups in Azure DevOps [Env vars](https://dev.azure.com/lab-inno/AI%20Portal/_library?itemtype=VariableGroups)
- **Dependencies:** Front Door, Storage account (assets), Keycloak (SSO integration via app)
- **Deployment process:** release pipeline (preprod/prod) [Releases](https://dev.azure.com/lab-inno/AI%20Portal/_release?_a=releases&view=mine&definitionId=4)

### 2.3 Backend/API (Source)
- **Hosting model:** App Service (shared “app” module)
- **Runtime & framework:** NestJS + Passport SAML
- **Secrets/config:** Azure DevOps variable groups; entrypoint handles DB migration
- **Persistence:** PostgreSQL Flexible Server; Storage account (assets)
- **Outbound dependencies:** Keycloak (SAML), AI Foundry
- **Ingress:** Front Door (public) to App Service

### 2.4 SSO / Keycloak (Source)
- **Keycloak hosting model:** Azure App Service
- **Realms:** TBD (Keycloak serves AIHub SSO)
- **Clients:** SAML clients configured: aihub-prod, aihub-preprod
- **Roles/groups:** TBD
- **Users:** TBD (source of truth to confirm)
- **Certificates/keys:** TLS for https://keycloak.lab-iwm.com/ (rotation TBD)

### 2.5 Networking & DNS
- **VNETs/Subnets:** TBD
- **Private endpoints:** TBD
- **Custom domains:** keycloak.lab-iwm.com (Keycloak), Front Door custom domain(s)
- **Certificates:** TLS certs for custom domains (issuer/renewal TBD)
- **Ingress/egress constraints:** Public ingress via Front Door

### 2.6 Identity & Access
- **Azure AD tenants involved:** Source tenant: labinno.onmicrosoft.com
- **Service principals / managed identities:** TBD
- **RBAC assignments:** TBD

### 2.7 Observability & Operations
- **Logging:** Application Insights [insights module](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/insights.tf)
- **Monitoring & alerts:** TBD
- **Backup/DR:** TBD

### 2.8 Risks & Migration Constraints
- **Tenant policy constraints:** Cross‑tenant migration (unknown constraints) — validate early
- **Data residency / compliance:** TBD
- **Downtime windows:** TBD

### 2.9 Source Project Config (Reference Links)
- [Env vars](https://dev.azure.com/lab-inno/AI%20Portal/_library?itemtype=VariableGroups)
- [Backend entrypoint (DB migration)](https://dev.azure.com/lab-inno/AI%20Portal/_git/backend?path=/entrypoint.sh)
- [Backend Dockerfile](https://dev.azure.com/lab-inno/AI%20Portal/_git/backend?path=/Dockerfile)
- [ACR repository (front + back)](https://portal.azure.com/#@labinno.onmicrosoft.com/resource/subscriptions/55b00a50-99c6-4084-94f3-9879f0f33728/resourceGroups/commons-resource-group/providers/Microsoft.ContainerRegistry/registries/aiportalregistry/repository)
- [ACR overview](https://portal.azure.com/#@labinno.onmicrosoft.com/resource/subscriptions/55b00a50-99c6-4084-94f3-9879f0f33728/resourceGroups/commons-resource-group/providers/Microsoft.ContainerRegistry/registries/aiportalregistry/overview)
- [Preprod/prod build logs](https://dev.azure.com/lab-inno/AI%20Portal/_build/results?buildId=21274&view=logs&j=5db9d08d-5587-54ed-5752-da7f5ebb50fa&t=1be6ee4b-cd49-5ffa-5e02-b66821cd1641&l=265)
- Latest tags:
	- aihub-backend: 21274 (latest)
	- aihub-frontend: 21624 (latest prod tag)
- Release trigger: [Releases](https://dev.azure.com/lab-inno/AI%20Portal/_release?_a=releases&view=mine&definitionId=4)

### 2.10 Source Cloud Components (Terraform)
- [Storage account](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/main.tf&version=GBmain&line=52&lineEnd=53&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents)
- [Front Door](https://dev.azure.com/lab-inno/AI%20Portal/_workitems/edit/2435)
- [App service (Front + Back)](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/app/main.tf&version=GBmain&line=9&lineEnd=10&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents)
- [Postgres flexible server](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/database.tf)
- [AI Foundry](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/openai.tf)
- [Logs analytics](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/app/main.tf&version=GBmain&line=64&lineEnd=65&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents)
- [Container registry (ACR)](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/acr.tf)
- [Azure Application Insight](https://dev.azure.com/lab-inno/AI%20Portal/_git/infra?path=/terraform/modules/insights.tf)
- [Keycloak App Service](https://portal.azure.com/#@labinno.onmicrosoft.com/resource/subscriptions/e4d4b19f-5566-418e-8597-040de3f1751b/resourceGroups/keycloak-inno-lab-rg/providers/Microsoft.Web/sites/Keycloak-inno-lab/appServices)

---

## Chapter 3 — Migration Tasks (Execution Plan)

> This chapter tracks the concrete migration tasks and their status.

### 3.1 Provision Required Infra Components (Target Tenant)
- **Pre-requisites**:
	- Target subscription and resource group for AIHub (We will the existing subscription )
	- Terraform config ready for core infra [aihub](../.cloud/examples/aihub/)
	- The ACR is deployed (check it with `az acr show -n sbxinfraacrkag` in `sbx-main-rg`)
- **Steps**:
	1. Provision ACR if not deployed (see [.cloud/tf-infra/acr.tf](../.cloud/tf-infra/acr.tf)).
	2. Provision the whole [aihub](../.cloud/examples/aihub/) infra with `glb-var dev && just tf-plan dev aihub` and `just tf-apply dev aihub`.
- **Output**:
	- Target infra ready for app deployment (ACR, ACA, AI Foundry, logs).
- **Status:** Completed on 2026-01-19

### 3.2 Seed Container Images into Target ACR
- **Pre-requisites**:
	- Remote ACR config in [.cloud/examples/aihub/dev.tfvars](../.cloud/examples/aihub/dev.tfvars).
	- Bastion VM can access both ACRs.A quick test must be done via just :
        - `just vm-exec '<the command goes here>' `
        -  a script exists to sync images (see [.cloud/modules/bastion/scripts/sync_remote_acr_acr.sh](../.cloud/modules/bastion/scripts/sync_remote_acr_acr.sh)).
- **Steps**:
	1. Confirm remote ACR images list in `remote_acr_config.images`.
	2. Check in the deployed bastion vm if the scripts was successfully run during  ["azurerm_virtual_machine_extension" "bastion_provision"](../.cloud/modules/bastion/main.tf#76).
	3. Validate the target ACR contains:
		 - `ai-hub-backend:21274`
		 - `ai-hub-frontend:21624`
- **Output**:
	- Target ACR seeded with backend and frontend images.
- **Status:** Completed on 2026-01-19 (bastion extension ran and pushed `ai-hub-backend:21274` and `ai-hub-frontend:21624`)

### 3.3 Build Custom Keycloak Image
- **Pre-requisites**:
	- Local Keycloak setup available in [.cloud/tools/keycloak](.cloud/tools/keycloak) (Dockerfile + compose).
	- Terraform configuration in [.cloud/tools/keycloak/tf](.cloud/tools/keycloak/tf) acting as the source of truth for Clients, Users, and Roles.
	- Realm export script [scripts/prepare-realm.js](scripts/prepare-realm.js) updated to explicitly export User Realm Roles (via `listRealmRoleMappings`).
	- Automated test script [scripts/test-auth-saml.sh](scripts/test-auth-saml.sh) available for verifying SAML flow and RBAC enforcement.
	- Backend authentication logic in [packages/todo-app-api/src/auth_saml](packages/todo-app-api/src/auth_saml) configured to map SAML attributes (specifically `Role`) to local User entities.
	- Keycloak admin access (default `admin/admin` in compose).
- **Steps**:
	1. Start local Keycloak in dev mode using `just kc-dc-up dev`.
	2. Apply Terraform configuration to provision the "api-realm", clients, and assign the `ADMIN` role to the test user:
		```bash
		just kc-tf-init && just kc-tf-plan && just kc-tf-apply
		```
	3. Export the Realm configuration to JSON:
		```bash
		just kc-export-realm
		```
		*Verification:* Ensure [.cloud/tools/keycloak/realms/sso-realm.json](.cloud/tools/keycloak/realms/sso-realm.json) contains `"realmRoles": ["ADMIN"]` for `test@domain.com`.
	4. Build and start the custom Keycloak image (using the `test` profile to emulate the final container artifact):
		```bash
		just kc-dc-up test "--build -d"
		```
	5. Verify the image functions correctly by running the end-to-end SAML test:
		```bash
		./scripts/test-auth-saml.sh
		```
		*Success Criteria:* Script returns `API Response: Hello World!` (confirming both AuthN and AuthZ/RBAC).
	6. Publish the validated image to the container registry:
		```bash
		just kc-publish-image
		```
	7. Configure and deploy Keycloak to Azure Container Apps (ACA):
		- Verify [.cloud/examples/aihub/aca.tf](.cloud/examples/aihub/aca.tf) references the published image `humaapi0registry/keycloak:latest` and configures the `keycloak` module.
		- Apply the infrastructure configuration:
		```bash
		glb-var dev && just tf-apply dev aihub
		```
- **Output**:
	- Custom Keycloak image `humaapi0registry/keycloak:latest` published to ACR.
	- `sso-realm.json` finalized with correct Role assignments.
- **Status:** Completed on 2026-01-19

### 3.4 Backend Migration
- **Pre-requisites**:
	- Infrastructure foundational layer [.cloud/tf-infra](config/.cloud/tf-infra) is fully deployed and up-to-date.
		*Verification command:* `glb-var infra && just tf-plan-infra` (Expect no changes).
	- AIHub project infrastructure [.cloud/examples/aihub](config/.cloud/examples/aihub) is fully deployed.
		*Verification command:* `glb-var dev && just tf-plan dev aihub` (Expect no changes).
	- Keycloak is deployed to ACA and reachable (via step 3.3).
	- Backend image `ai-hub-backend:21274` is present in the target ACR (provisioned in `tf-infra/acr.tf`).
	- Required Environment Variables are identified for mapping in `aca.tf`:
		```bash
		# App
		APP_NAME=ai-hub-backend
		APP_PORT=8080
		ENABLE_CORS=true
		CORS_ALLOWED_ORIGINS=* # Update with Frontend URL later
		NODE_ENV=production
		FRONTEND_URL=https://<frontend-fqdn>

		# Database
		DATABASE_URL=postgres://<admin>:<pass>@<postgres-fqdn>:5432/aihub?ssl=true

		# AI
		API_KEY=<outputs from module.ai_foundry>
		API_ENDPOINT=<outputs from module.ai_foundry>
		API_MODEL_NAME=gpt-4.1
		API_VERSION=2025-04-14

		# SSO Login (Matches Keycloak ACA FQDN)
		SAML_ENTRYPOINT=https://<keycloak-fqdn>/realms/api-realm/protocol/saml
		SAML_ISSUER="aihub-prod"
		SAML_CERT=<Content of KC_REALM_AIHUB-PROD_SAML_SIGNING_CERTIFICATE>
		SAML_PATH=/auth/saml/callback

		# JWT
		JWT_SECRET=<Generate Strong Secret>
		JWT_EXPIRES_IN=3600s
		JWT_COOKIE_NAME=Authentication
		JWT_REFRESH_COOKIE=rt
		JWT_REFRESH_EXPIRES_IN=604800
		```
- **Steps**:
	1. Update [.cloud/examples/aihub/aca.tf](.cloud/examples/aihub/aca.tf) `backend_aihub` module to include the environment variables listed above.
	2. Map sensitive values (DB pass, JWT Secret) to Secrets/KeyVault. Use dynamic retrieval for `API_KEY` from `module.ai_foundry`.
	3. Apply the configuration:
		```bash
		glb-var dev && just tf-apply dev aihub
		```
	4. Validate Backend health and DB connection via logs:
		```bash
		az containerapp logs show -n containerappdemo -g <resource-group> --follow
		```
	5. Validate SAML login flow (redirection to Keycloak and back).
- **Output**:
	- Backend running in target tenant with correct configuration and verified SSO.
- **Status:** Completed on 2026-01-20

### 3.5 Frontend Migration
- **Pre-requisites**:
	- Infrastructure foundational layer [.cloud/tf-infra](config/.cloud/tf-infra) is fully deployed.
	- AIHub project infrastructure [.cloud/examples/aihub](config/.cloud/examples/aihub) is fully deployed.
	- Backend module (`backend_aihub`) and Keycloak module (`keycloak`) are deployed and reachable (Task 3.4).
	- Frontend image `ai-hub-frontend:21624` is present in the target ACR.
	- Required Environment Variables:
		- `API_URL=https://<backend-fqdn>` (Backend API Endpoint such as `https://containerappdemo-dev...`)
- **Steps**:
	1. Update [.cloud/examples/aihub/aca.tf](.cloud/examples/aihub/aca.tf) to include the `frontend_aihub` module. Use `backend_aihub` as a template but configure for:
		- **Image**: `ai-hub-frontend:21624`
		- **Port**: `80` (Nginx default)
		- **Environment**: Pass `API_URL` using the output FQDN from the backend module.
	2. Apply the configuration:
		```bash
		glb-var dev && just tf-apply dev aihub
		```
	3. Validate Frontend health:
		- Check accessibility via the generated ACA FQDN.
		- Verify API calls to the backend (check browser network tab or logs).
- **Output**:
	- Frontend running in ACA, serving the React app via Nginx, and successfully communicating with the Backend.

