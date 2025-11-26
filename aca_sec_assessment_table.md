# ACA & ACA Environment – Security Assessment Table

This document translates the requirements from `aca_sec_assement.checklist.md` into a structured table format, grouped by security layers and specific topics.

## Network & Perimeter Security (Layer 1)

| Topic | Requirement | Status |
| :--- | :--- | :---: |
| Global Constraints | No public endpoints are allowed for ACA Environments and ACA apps. | [X] |
| Global Constraints | Centralized egress via Azure Firewall / proxy. | [X] |
| Global Constraints | Private endpoints for all PaaS dependencies (ACR, Key Vault, Storage, DB, Log Analytics). | [ ] |
| VNet & Subnet Design | A custom VNet dedicated (or at least reserved) for ACA and dependencies is defined and implemented. | [X] |
| VNet & Subnet Design | An ACA environment subnet is defined with CIDR /27+ and 12 reserved IPs accounted for. | [X] |
| VNet & Subnet Design | The ACA subnet is delegated to `Microsoft.App/environments`. | [X] |
| VNet & Subnet Design | Additional subnets are defined as needed (DB, Storage). | [ ] |
| VNet & Subnet Design | Subnets for private endpoints are defined. | [X] |
| ACA Environment Creation | The ACA Environment is created as a Workload Profile Environment + Consumption (v2). | [ ] |
| ACA Environment Creation | The ACA Environment is attached to the custom VNet and the delegated subnet. | [X] |
| ACA Environment Creation | Public Network Access = Disabled is configured for the environment. | [X] |
| ACA Environment Creation | The Virtual IP is configured as Internal (internal load balancer only). | [X] |
| ACA Environment Creation | The environment exposes no public FQDN reachable from the Internet. | [X] |
| NSGs & UDRs | NSG allows inbound traffic only from trusted sources via ILB. | [X] |
| NSGs & UDRs | NSG denies any direct inbound Internet traffic. | [X] |
| NSGs & UDRs | NSG allows necessary ports for health probes and app access `(80/31080, 443/31443, 30000–32767 as applicable)`. | [X] |
| NSGs & UDRs | UDRs route default outbound traffic `0.0.0.0/0` to Azure Firewall (+ proxy). | [X] |
| NSGs & UDRs | No direct Internet egress from the ACA subnet is possible. | [X] |
| Ingress Configuration | ACA Environment ingress is configured as Internal Ingress only. | [X] |
| Ingress Configuration | An Internal Load Balancer (ILB) is present inside the VNet for the environment. | [X] |
| Ingress Configuration | For each ACA app, only internal ingress (no public ingress) is configured. | [X] |
| Ingress Configuration | Any required external exposure is routed via App Gateway WAF / Front Door Premium. | [ ] |
| Egress Configuration | ACA subnet UDRs are configured so that all outbound traffic is sent to Azure Firewall / proxy. | [X] |
| Egress Configuration | Outbound destinations are restricted to approved endpoints only (ACR, Entra ID, Monitor, KV, etc.). | [ ] |
| Private Endpoints | Private Endpoints are created for ACR, Key Vault, Storage, Database, Log Analytics. | [ ] |
| DNS & Custom Domains | An Azure Private DNS Zone exists for the internal apex domain for the ACA Environment. | [X] |
| DNS & Custom Domains | An A record is configured mapping the apex domain to the static IP of ACA ILB. | [X] |
| DNS & Custom Domains | The ACA VNet is linked to the Private DNS Zone. | [X] |
| DNS & Custom Domains | Any custom internal FQDNs for apps resolve only to internal IPs. | [X] |
| DNS & Custom Domains | Azure Private DNS Zones exist for ACR, Key Vault, Storage and are linked to the ACA VNet. | [X] |
| DNS & Custom Domains | Azure Private DNS Zones exist for Database and Log Analytics and are linked to the ACA VNet. | [ ] |
| Policy Alignment | Public network access is disabled for Container Apps Environment, apps, and registries. | [ ] |
| Policy Alignment | Network injection/VNet integration is used for the ACA Environment. | [X] |

## Authentication & IAM (Layer 2)

| Topic | Requirement | Status |
| :--- | :--- | :---: |
| Global Constraints | Use of Managed Identities only (no shared keys, no embedded secrets). | [X] |
| Management Plane Controls | Azure roles for ACA management are restricted to trusted admins only. | [ ] |
| Management Plane Controls | Conditional Access and MFA are enforced on admin accounts. | [ ] |
| Management Plane Controls | PIM (Privileged Identity Management) is used for time‑bound admin roles. | [ ] |
| Workload Managed Identities | For each ACA app, the use of System‑Assigned MI, User‑Assigned MI, or both is explicitly defined. | [X] |
| Workload Managed Identities | All necessary User‑Assigned Managed Identities for shared workloads are created. | [X] |
| Workload Managed Identities | Least‑privilege RBAC roles are assigned to each MI (AcrPull, Key Vault Secrets User, etc.). | [X] |
| Workload Managed Identities | ACA apps do not rely on shared keys/SAS where policies forbid them. | [X] |
| Application Authentication | ACA Authentication/Authorization (Easy Auth) is enabled for HTTP/HTTPS apps. | [ ] |
| Application Authentication | Easy Auth is configured to use Entra ID with no anonymous access. | [ ] |
| Application Authentication | For internal APIs, Entra ID / OAuth2 is used for internal traffic where required. | [ ] |
| Application Authentication | mTLS is designed and enforced at App Gateway/Front Door or internal gateway where needed. | [ ] |
| Secret Management | Azure Key Vault instances are created or identified. | [X] |
| Secret Management | All secrets/keys/certificates for ACA apps are stored in Key Vault. | [X] |
| Secret Management | ACA apps consume secrets via Key Vault + Managed Identity. | [X] |
| Policy Alignment | Managed Identity is enabled for all Container Apps. | [X] |
| Policy Alignment | Shared key access is prevented for storage accounts. | [X] |
| Policy Alignment | Authentication is enabled on Container Apps (Entra ID via Easy Auth). | [ ] |

## Logging, Monitoring & Threat Detection (Layer 3)

| Topic | Requirement | Status |
| :--- | :--- | :---: |
| Global Constraints | Logging to Event Hub / Log Analytics / Splunk is configured. | [ ] |
| Diagnostic Settings | Azure Monitor logs are enabled for the ACA Environment and apps. | [ ] |
| Diagnostic Settings | Diagnostic Settings send logs to Event Hub, Log Analytics, and Corporate SIEM. | [ ] |
| Diagnostic Settings | Log categories `(SystemLogs, AppLogs, IngressLogs, KubeAudit, AutoscaleEvents)` are enabled. | [ ] |
| Metrics & Health Monitoring | Monitoring and alerting are configured for `CPU/Memory, HTTP errors, Scaling events and failures`. | [ ] |
| Threat Detection | Images are continuously scanned for CVEs. | [ ] |
| Threat Detection | ACA logs are correlated with NSG/Firewall/network flow logs for threat detection. | [ ] |
| Threat Detection | Alerts are implemented for unauthorized ingress, unusual outbound traffic, auth failures. | [ ] |
| Threat Detection | Runtime behavior monitoring for containers is planned or implemented. | [ ] |
| Policy Alignment | Diagnostic logs to Event Hub are configured for ACA Environment. | [ ] |

## Data Protection & Compliance (Layer 4)

| Topic | Requirement | Status |
| :--- | :--- | :---: |
| Global Constraints | All ACA-related resources are deployed only in Switzerland regions. | [ ] |
| Global Constraints | Corporate requirements are defined and documented. | [ ] |
| Encryption in Transit | TLS ≥ 1.2 is enforced on all ACA ingress endpoints. | [X] |
| Encryption in Transit | No configuration uses `allowInsecure = true` for HTTP. | [X] |
| Encryption in Transit | TLS certificates are managed through Key Vault. | [X] |
| Encryption at Rest | All data written by ACA workloads is classified `(ephemeral vs persistent, sensitivity)`. | [ ] |
| Encryption at Rest | Persistent data is stored using appropriate services ***(Storage, DB, KV) with encryption***. | [X] |
| Encryption at Rest | Public access to storage accounts is denied. | [X] |
| Encryption at Rest | Access is allowed only through private endpoints. | [X] |
| Encryption at Rest | Shared key / SAS usage is disabled on storage; Entra ID + RBAC is used. | [X] |
| Encryption at Rest | Application logic treats the local container file system as ephemeral. | [X] |
| Encryption at Rest | Compliance with security policy regarding storage account keys is validated (if Azure Files used). | [ ] |
| Geo-Compliance | Cross‑region replication is documented and formally approved (if required). | [ ] |
| Maintenance & Operations | A maintenance window for non‑critical ACA Environment updates is configured (>8h, low impact). | [ ] |
| Policy Alignment | Terraform configurations are aligned with key policies. | [ ] |
