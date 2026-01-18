# Run api server in watch mode

[group('terraform')]
[working-directory: '.cloud/tf-infra']
@tf-init-infra:
    terraform init -var-file="infra.tfvars" \
        -var="env=infra" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
[working-directory: '.cloud/tf-infra']
@tf-plan-infra:
    terraform plan -var-file="infra.tfvars" \
        -out "infra.tfplan" \
        -var="env=infra" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]       
[working-directory: '.cloud/tf-infra']    
@tf-apply-infra:
    terraform apply "infra.tfplan"

# Destroy infrastructure
[group('terraform')]
[working-directory: '.cloud/tf-infra']
@tf-destroy-infra:
    terraform destroy -var-file="infra.tfvars" \
        -var="env=infra" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
@tf-fmt *target:
    terraform -chdir={{target}}  fmt -recursive

[group('terraform')]
@tf-fmt-all:
    just tf-fmt .cloud/tf-infra
    just tf-fmt .cloud/examples
    just tf-fmt .cloud/modules

[group('terraform')]
[working-directory: '.cloud/examples']
@tf-init env dir:
    terraform -chdir={{dir}} init -var-file="{{env}}.tfvars" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
[working-directory: '.cloud/examples']
@tf-plan env dir:
    terraform -chdir={{dir}} plan -var-file="{{env}}.tfvars" \
        -out "{{env}}.tfplan" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
[working-directory: '.cloud/examples']
@tf-apply env dir:
    terraform -chdir={{dir}} apply "{{env}}.tfplan"

[group('terraform')]
[working-directory: '.cloud/examples']
@tf-destroy env:
    terraform destroy -var-file="{{env}}.tfvars" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('docker')]
[working-directory: '.cloud/docker']
@prepare-dist:
    @echo "Building app..."
    just todo-build
    @echo "Preparing dist folder..."
    cp -r ../../packages/todo-app-api/dist .

[group('docker')]
[working-directory: '.cloud/docker']
@docker-up args="": prepare-dist
    # cp -r ../../packages/todo-app-api/dist ./dist
    docker compose up {{args}}

[group('docker')]
[working-directory: '.cloud/docker']
@docker-down:
    docker compose down

[group('docker')]
[working-directory: '.cloud/docker']
@docker-build: prepare-dist
    docker build -t local/todo-app-api:latest .

[group('docker')]
[working-directory: '.cloud/docker']
@docker-push-acr: docker-build
    @echo "Logging into ACR..."
    az acr login --name sbxinfraacrkag
    @echo "Tagging image..."
    docker tag local/todo-app-api:latest sbxinfraacrkag.azurecr.io/local/todo-app-api:latest
    @echo "Pushing image..."
    docker push sbxinfraacrkag.azurecr.io/local/todo-app-api:latest

### API Server Tasks ###
[group('api')]
[working-directory: 'packages/todo-app-api']
@todo-dev:
    #!/usr/bin/env bash
    source .env
    # For local development with self-signed certs, we can disable TLS verification
    # if NODE_EXTRA_CA_CERTS is not working as expected.
    echo "Port is: $PORT"
    echo "Trusting cert at: $NODE_EXTRA_CA_CERTS"
    yarn start

[group('api')]
[working-directory: 'packages/todo-app-api']
@todo-test:
    #!/usr/bin/env bash
    source .env
    yarn test:e2e

[group('api')]
[working-directory: 'packages/todo-app-api']
@todo-seed:
    #!/usr/bin/env bash
    source .env
    echo "Seeding database..."
    yarn schema:recreate

[group('api')]
[working-directory: 'packages/todo-app-api']
@todo-build:
    yarn build

[group('service')]
[working-directory: 'packages/todo-app-api']
@todo-svc-azurite:
    yarn azurite:start

[group('service')]
[working-directory: 'packages/todo-app-api']
@todo-svc-azurite-cert:
    ./scripts/generate-certs.sh

[group('ops')]
vm-exec +command:
    #!/usr/bin/env bash
    if [ -z "$TF_VAR_admin_password" ]; then
        echo "Error: TF_VAR_admin_password is not set. Please run 'glb-var infra' first."
        exit 1
    fi

    pushd .cloud/tf-infra > /dev/null
    IP=$(terraform output -raw nexus_vm_public_ip)
    popd > /dev/null

    if [ -z "$IP" ]; then
        echo "Error: Could not get Nexus VM Public IP."
        exit 1
    fi

    echo "Running on $IP..."
    sshpass -p "$TF_VAR_admin_password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 nexusadmin@$IP "{{command}}"

[group('ops')]
vm-scp local_file remote_path="":
    #!/usr/bin/env bash
    if [ -z "$TF_VAR_admin_password" ]; then
        echo "Error: TF_VAR_admin_password is not set. Please run 'glb-var infra' first."
        exit 1
    fi

    pushd .cloud/tf-infra > /dev/null
    IP=$(terraform output -raw nexus_vm_public_ip)
    popd > /dev/null

    if [ -z "$IP" ]; then
        echo "Error: Could not get Nexus VM Public IP."
        exit 1
    fi

    DEST="{{remote_path}}"
    if [ -z "$DEST" ]; then
        DEST="/home/nexusadmin/$(basename {{local_file}})"
    fi

    echo "Copying {{local_file}} to $IP:$DEST..."
    sshpass -p "$TF_VAR_admin_password" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 {{local_file}} nexusadmin@$IP:$DEST

### Keycloak Tasks ###
[group('keycloak-docker')]
[working-directory: '.cloud/tools/keycloak']
@kc-dc-up profile args="":
    docker compose --profile {{profile}} up {{args}}

[group('keycloak-docker')]
[working-directory: '.cloud/tools/keycloak']
@kc-dc-down profile:
    docker compose  --profile {{profile}} down

[group('keycloak-docker')]
@kc-publish-image:
    docker tag keycloak-keycloak.test:latest humaapi0registry/keycloak:latest
    docker push humaapi0registry/keycloak:latest

[group('keycloak-config')]
@kc-export-realm:
    yarn realm:config -s "supersecret" \
    -r "api-realm" \
     -f '.cloud/tools/keycloak/realms/sso-realm.json'

[group('keycloak-config')]
@kc-test-realm:
    ./scripts/test-auth.sh

[group('keycloak-tf')]
[working-directory: '.cloud/tools/keycloak/tf']
@kc-tf-init args="":
    terraform init {{args}}

[group('keycloak-tf')]
[working-directory: '.cloud/tools/keycloak/tf']
@kc-tf-plan:
    terraform plan -out "keycloak.tfplan"

[group('keycloak-tf')]
[working-directory: '.cloud/tools/keycloak/tf']
@kc-tf-apply:
    terraform apply "keycloak.tfplan"

[group('keycloak-tf')]
[working-directory: '.cloud/tools/keycloak/tf']
@kc-tf-destroy:
    terraform destroy



