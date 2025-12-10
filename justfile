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
    just tf-fmt .cloud/tf
    just tf-fmt .cloud/modules

[group('terraform')]
[working-directory: '.cloud/tf']
@tf-init env:
    terraform init -var-file="{{env}}.tfvars" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
[working-directory: '.cloud/tf']
@tf-plan env:
    terraform plan -var-file="{{env}}.tfvars" \
        -out "{{env}}.tfplan" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('terraform')]
[working-directory: '.cloud/tf']
@tf-apply env:
    terraform apply "{{env}}.tfplan"

[group('terraform')]
[working-directory: '.cloud/tf']
@tf-destroy env:
    terraform destroy -var-file="{{env}}.tfvars" \
        -var="env={{env}}" \
        -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
        -var="tenant_id=${ARM_TENANT_ID}"

[group('docker')]
[working-directory: '.cloud/docker']
@prepare-dist:
    @echo "Preparing dist folder..."
    cp -r ../../packages/todo-app-api/dist .

[group('docker')]
[working-directory: '.cloud/docker']
@docker-up:
    cp -r ../../packages/todo-app-api/dist ./dist
    docker compose up

[group('docker')]
[working-directory: '.cloud/docker']
@docker-build: prepare-dist
    docker build -t local/todo-app-api:latest .
