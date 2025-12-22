# Need

The goal of this feature is to implement easy authentication with Keycloak in container apps on Azure. This feature will streamline the process of authenticating users and services using Keycloak as the identity provider. Before this feature, users had to manually configure authentication settings at the api level, which involved multiple steps and was prone to errors.

Involved components:
- Keycloak
- Container Apps
- Easy Auth

## 1. Previous Works

- The easy-auth feature was added inside the [container apps module](../.cloud/modules/container_app/container_app.tf#L108). The configuration was then added on the module declaration in the [container apps module declaration](../.cloud/tf/main.tf#L186).
- A keycloak deployment was added in [keycloak deployment](../.cloud/tf/main.tf#L72) to provide the identity provider for authentication.
- To streamline the test against the deployed container app with Keycloak authentication, a public IP was added inside the nexus module in [nexus module declaration](../.cloud/modules/nexus_vm/network.tf#L4) and a just recipe was created in [justfile](../justfile#L139) to facilitate the testing process.

## 2. Previous encountered issues

1. **Internal DNS Resolution for Custom Domains**: The Container App's authentication sidecar failed to resolve the custom domain (`keycloak-dev.sbx-kag.io`) of the Keycloak instance within the same environment. This prevented the sidecar from downloading the OpenID Connect configuration required for initialization.

2. **SSL Certificate Trust in Sidecar**: HTTPS communication between the EasyAuth sidecar and Keycloak failed due to untrusted self-signed certificates. The sidecar does not natively trust the custom CA used in the sandbox, and disabling SSL validation is not straightforward for the managed sidecar.

3. **Keycloak Realm Availability**: During connectivity tests, the `todo-app` realm returned a `404 Not Found` error when queried from the application container, while the `master` realm was accessible. This suggests the realm import process defined in the Keycloak container arguments or startup scripts may have failed or not persisted.

4. **Default FQDN Instability**: Using the default Azure Container App FQDN (e.g., `*.azurecontainerapps.io`) for internal communication was ruled out because the domain includes a revision-specific suffix. This suffix changes with every new revision, making it unsuitable for static Terraform configuration.

5. **Azure CLI Rate Limiting**: Extensive debugging using `az containerapp exec` to test internal connectivity triggered `429 Too Many Requests` errors from the Azure API, temporarily blocking access to the container console.

## 3. New approach to solve the issues and implement the feature

1. **Simplification of the testing environment**: Due to the complexity of troubleshooting deployed container apps with Keycloak authentication, we should ensure that the prerequisite configurations on the Keycloak side are correctly set up before integrating with the container app. We should also use authentication methods at the [todo-app-api](../packages/todo-app-api/src) with passport jwt package to test the Keycloak authentication flow directly from the application code, rather than relying solely on the EasyAuth sidecar.

2. **The final local testing environment**: At the end, we shoud have the [docker-compose setup](../.cloud/docker/docker-compose.yml) that includes:
   - A Keycloak instance with the `todo-app` realm and necessary clients and users pre-configured.
   - The local version of the todo-app-api container configured to authenticate against the Keycloak instance.
   - And other necessary services (azurite, postgres etc ...) required for the application to function.

3. **Testing**: We should then write a local testing script that simulates the authentication flow against deployed keycloak instance with **client + secret** to obtain the access token and use that token to access the deployed todo-app-api. this testing script must have args so that the FQDNs of both keycloak and todo-app-api could be passed in as parameters.

4. **The custom keycloak image accessible publicly**: Finally, we should push the custom Keycloak image to docker hub, so that configuration can be reused in the future without needing to rebuild the image each time.

5. **Deployment**: Once everything is tested and verified locally, we could then deployed the publicly accessible custom Keycloak image on container apps as well as the updated todo-app-api container with Keycloak authentication integrated.

6. **Testing deployed environment**: After deployment, we should run the testing script against the deployed instances of Keycloak and todo-app-api to ensure that the authentication flow works correctly in the production environment. The script must be scp -o into the nexus VM and executed from there to simulate real-world access scenarios.

7. **Configuring the easy auth with keycloak**: Finally, we should configure the easy-auth settings in the container app module to point to the deployed Keycloak instance, ensuring that the authentication flow is seamless for end-users accessing the application. But before that, we should deactivate token revalidation in api side.

## 4. Task List

### 4.1 Create a custom Keycloak Docker image with the `sso` realm pre-configured
- **Pre-requisites**:
    - folder existing at `./.cloud/tools/keycloak` 
    - Inside this folder, there should be:
        - `Dockerfile` : to build the custom keycloak image
        - `docker-compose.yml` : to run the keycloak instance locally for testing
        <!-- - `realms/setup-realm.json`: the first setup that holds the terraform service account to plan and apply --> It's no longer needed as we are using admin-cli
        - `tf/`: folder that holds the terraform files to create the `sso` realm with necessary clients and users.
    - A script at `./scripts/prepare-realm.js` to prepare the final realm configuration file by omitting sensitive information.
- **Steps**:
    1. Run a local Keycloak instance using `docker-compose.yml` using `just kc-dc-up "dev" "-d --build"`
    2. Plan the configuration using `just kc-tf-plan`
    3. Apply the configuration using `just kc-tf-apply`
    4. Test the configuration using `just kc-test-realm`
    5. Export the configured realm using `just kc-export-realm`
    6. Down the previous running keycloak instance using `just kc-dc-down "dev"`
    7. Run the final keycloak instance using `just kc-dc-up "test" "-d --build"` to verify the exported realm works as expected.
    8. Run the testing script `just kc-test-realm` to verify the configuration works as expected.


- **Output**:
    - `realms/sso-realm.json` : the realm configuration exported from a running keycloak that has the configuration applied.

### 4.2 Configure todo-app-api with Keycloak authentication
- **Pre-requisites**:
    - `realms/sso-realm.json` generated from step 4.1.
    - `packages/todo-app-api` codebase.
    - Installed dependencies in `packages/todo-app-api`: `@nestjs/passport`, `passport`, `@nestjs/jwt`, `passport-jwt`,`jwks-rsa`.
    - Installed dev dependencies in `packages/todo-app-api`: `@types/passport-jwt`.
- **Steps**:
    1. Implement a Passport JWT strategy to validate tokens against the Keycloak issuer.
    2. Protect API routes using the configured strategy.
    3. Update `.cloud/docker/docker-compose.yml` to include the `keycloak` service using the image `keycloak-keycloak.test:latest` produced in step 4.1 and link it to `todo-app-api`.
    4. Configure `todo-app-api` environment variables to point to the Keycloak container (e.g., `AUTH_ISSUER_URL`).
    6. Start the full stack using `just docker-up`.
    7. Verify the flow by obtaining a token from Keycloak and calling a protected API endpoint.
- **Output**:
    - Updated `todo-app-api` with authentication logic.
    - Functional local environment with API and Keycloak.

### 4.3 Publish the customized keycloak image to docker hub
- **Pre-requisites**:
    - The custom Keycloak image `keycloak-keycloak.test:latest` built in task 4.1.
    - Docker Hub account credentials.
- **Steps**:
    1. Log in to Docker Hub using `docker login`.
    2. Tag and push the image using `just kc-publish-image`.
- **Output**:
    - Publicly accessible Docker image on Docker Hub.
    - Verify with: `docker manifest inspect humaapi0registry/keycloak:latest`

### 4.4 Deploy and Verify Keycloak and Todo App API on Azure
- **Pre-requisites**:
    - Publicly accessible Keycloak image `humaapi0registry/keycloak:latest` (from 4.3).
    - Updated `todo-app-api` code (from 4.2).
    - Terraform configuration files in `.cloud/tf`.
    - ACR name: `sbxinfraacrkag`.
- **Steps**:
    1. Update `scripts/test-auth.sh` to:
        - Accept `KEYCLOAK_URL` and `TODO_API_URL` as arguments.
        - Perform a request to the Todo App API using the obtained token.
    2. Update `.cloud/tf/main.tf`:
        - Change Keycloak image to `humaapi0registry/keycloak:latest`.
        - Add `AUTH_ISSUER_URL` and `AUTH_JWKS_URI` env vars to `todo-app-api` container.
    3. Apply Terraform configuration:
        - `glb-var dev`
        - `just tf-plan dev`
        - `just tf-apply dev`
    5. Verify deployment:
        - Copy script to Nexus VM: `scp scripts/test-auth.sh nexusadmin@<nexus_ip>:/home/nexusadmin/test-auth.sh`
        - Run script: `just vm-exec './test-auth.sh <keycloak_url> <todo_app_url>'`
- **Output**:
    - Deployed Keycloak and Todo App API on Azure Container Apps.
    - Successful execution of `test-auth.sh` on Nexus VM.

### 4.5 Configure Easy Auth with Keycloak
- **Pre-requisites**:
    - Deployed and verified Keycloak and Todo App API (from 4.4).
    - The easy-auth feature added in the container apps module.
- **Steps**:
    1. Comment out JWT validation @UseGuards(JwtAuthGuard) in `packages/todo-app-api/src/todos/todo.controller.ts` to disable JWT validation.
    2. just run`just docker-up "--build -d"`(it will build, and prepare artefact run api ) to verify the api still works without jwt validation.
    3. Try to access the api without token, it should work `curl http://localhost:3000/todos`
    4. Update `.cloud/tf/main.tf` to enable Easy Auth for `todo-app-api`.
        - Configure `auth_config` (or equivalent in the module) to use Keycloak as an OIDC provider.
            - Client ID: `api-sso`
            - Client Secret: `supersecret` (or reference the secret)
            - Issuer URL: `https://keycloak-dev.sbx-kag.io/realms/api-realm`
    3. Apply Terraform configuration:
        - `just tf-apply dev`
    4. Verify:
        - Accessing the API without a token should result in a 401 or redirect (depending on config).
        - Accessing with a valid token (obtained via script) should work.
- **Output**:
    - `todo-app-api` protected by Easy Auth.