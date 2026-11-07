
# Secure Internal Developer Platform — Azure (Free Tier)

A mini platform where developers deploy applications by submitting a single YAML file. The platform handles Kubernetes manifests, secrets, admission policies, network isolation, and GitOps sync automatically.

## Architecture

Developer (application.yaml)
│
▼
Azure DevOps Pipeline (build → scan → render → commit)
│
▼
GitOps Repo (Helm chart + rendered manifests)
│
▼
Argo CD (auto-sync / manual-sync per environment)
│
▼
AKS Cluster (Free tier)
├── OPA Gatekeeper (admission policies)
├── Calico NetworkPolicy (default-deny)
├── Azure Key Vault CSI Driver (secrets via Workload Identity)
└── HPA (auto-scaling)


## Stack

| Component | Service | Cost |
|-----------|---------|------|
| Kubernetes | AKS (Free tier) | $0 |
| Nodes | 2× Standard_B2s_v2 | $0 (12 months) |
| Container Registry | ACR Basic | ~$5/mo |
| Secrets | Azure Key Vault Standard | ~$0.01/mo |
| GitOps | Argo CD (in-cluster) | $0 |
| Admission | OPA Gatekeeper | $0 |
| Network Policy | Calico (built into AKS) | $0 |
| IaC | Terraform (azurerm v4.81) | $0 |
| CI/CD | Azure DevOps (5 users) | $0 |
| Image Scanning | Trivy (in pipeline) | $0 |
| Identity | Microsoft Entra Workload ID | $0 |

**Total: ~$5/mo** (first 12 months)

## Prerequisites

- Azure account (free or pay-as-you-go)
- Azure CLI 2.60+
- Terraform 1.7+
- kubectl
- Helm 3.14+
- Docker
- Git

## Project Structure

secure-idp-azure/
├── terraform/
│ ├── main.tf
│ ├── providers.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── modules/
│ ├── network/ # VNet, subnets, NSG
│ ├── aks/ # AKS cluster (Free tier)
│ ├── acr/ # ACR Basic
│ ├── key-vault/ # Azure Key Vault + secrets
│ └── workload-identity/ # UAMI + federated credential
├── gitops/
│ ├── apps/
│ │ ├── argocd-bootstrap.yaml
│ │ ├── production/
│ │ └── staging/
│ ├── argocd/
│ │ └── rbac-configmap.yaml
│ ├── clusters/
│ │ └── in-cluster.yaml
│ └── projects/
│ ├── production.yaml
│ └── staging.yaml
├── helm-charts/
│ └── payments-api/
│ ├── Chart.yaml
│ ├── values.yaml
│ ├── values-staging.yaml
│ ├── values-production.yaml
│ └── templates/
│ ├── deployment.yaml
│ ├── service.yaml
│ ├── ingress.yaml
│ ├── networkpolicy.yaml
│ ├── hpa.yaml
│ ├── serviceaccount.yaml
│ ├── secretproviderclass.yaml
│ └── _helpers.tpl
├── platform/
│ ├── gatekeeper/
│ │ ├── constraints/
│ │ └── install.yaml
│ ├── network-policies/
│ │ ├── default-deny.yaml
│ │ └── allow-dns.yaml
│ └── schema/
│ └── application.schema.json
├── pipeline/
│ ├── azure-pipelines.yaml
│ └── tasks/
│ ├── render-helm.sh
│ ├── trivy-scan.sh
│ └── validate-schema.sh
├── docs/
│ ├── architecture.md
│ ├── developer-guide.md
│ └── runbook.md
├── application.yaml
└── .gitignore


## Quick Start

### 1. Bootstrap Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

This creates:

Resource Group (idp-rg)
VNet + Subnets + NSG
AKS cluster (Free tier, K8s 1.30, Calico, Workload Identity)
ACR Basic
Key Vault Standard + seed secrets
User-Assigned Managed Identity + Federated Credential
2. Get Cluster Credentials
az aks get-credentials -n idp-aks -g idp-rg --admin
kubectl get nodes

3. Install Add-ons
# Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml

# Cert Manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set installCRDs=true

# Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Argo CD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace \
  --set controller.replicas=1 \
  --set server.replicas=1 \
  --set server.service.type=ClusterIP

4. Apply Security Policies
# Gatekeeper constraints
kubectl apply -f ../platform/gatekeeper/constraints/

# Default-deny network policies
kubectl apply -f ../platform/network-policies/

5. Create Namespaces & ServiceAccount
kubectl create ns staging production platform

# Workload Identity ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-reader
  namespace: platform
  annotations:
    azure.workload.identity/client-id: "$(cd terraform && terraform output workload_identity_client_id)"
EOF

6. Bootstrap Argo CD via GitOps
kubectl apply -f ../gitops/apps/argocd-bootstrap.yaml
kubectl get applications -n argocd

Developer Workflow
A developer submits a single file:

# application.yaml
application:
  name: payments-api
  image: regidp5b41dd.azurecr.io/payments-api:1.2.0
  replicas: 3
  environment: production
  ports:
    - containerPort: 8080
  secrets:
    - name: DB_PASSWORD
      source: keyvault
      key: payments-db-password
    - name: API_KEY
      source: keyvault
      key: payments-api-key
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: "2"
      memory: 1Gi
  hpa:
    minReplicas: 3
    maxReplicas: 10
    targetCPU: 70

The platform handles:

✅ Schema validation
✅ Docker build + push to ACR
✅ Trivy image scan (blocks on HIGH/CRITICAL)
✅ Helm chart rendering
✅ GitOps commit
✅ Argo CD sync
✅ Gatekeeper admission (labels, probes, no-latest, resources, security context)
✅ NetworkPolicy (default-deny, allow only declared ports)
✅ Secrets from Key Vault via CSI Driver + Workload Identity
✅ HPA auto-scaling
Security Model
Layer	Mechanism
Secrets	Azure Key Vault + CSI Driver + Workload Identity (no static creds)
RBAC (human)	Azure RBAC (AKS Cluster Admin / AKS Cluster User)
RBAC (pod→Azure)	Microsoft Entra Workload ID (federated SA → UAMI)
RBAC (in-cluster)	Kubernetes Role/RoleBinding per namespace
Admission	OPA Gatekeeper (no-latest, required labels, probes, resources, restricted PSP)
Network	Calico NetworkPolicy (default-deny, allow only declared ports)
Image Scanning	Trivy in pipeline (blocks on HIGH/CRITICAL)
Pod Security	pod-security.kubernetes.io/enforce: restricted labels

Key Terraform Outputs
cd terraform
terraform output

Output	Example
cluster_name	idp-aks
acr_login_server	regidp5b41dd.azurecr.io
key_vault_name	idp-kv-a7x3f2
workload_identity_client_id	xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
vnet_id	/subscriptions/.../virtualNetworks/idp-vnet

Teardown
cd terraform
terraform destroy -auto-approve

Troubleshooting
Symptom	Cause	Fix
hudson.model.Hudson.Read in kubectl errors	~/.kube/config points to Jenkins	az aks get-credentials -n idp-aks -g idp-rg --admin
K8sVersionNotSupported	Version requires LTS (paid)	Use non-LTS version (e.g., 1.30)
VaultAlreadyExists	Vault name taken globally	Use a unique name (add random suffix)
Unreadable module directory	modules/ not in terraform/	mv modules terraform/modules
.terraform/ too large for git	Provider binary committed	git rm -r --cached terraform/.terraform + .gitignore

Notes
azurerm provider v4 — several arguments changed from v2/v3:
network_plugin → network_profile.network_plugin
azure_rbac_enabled → removed (always on)
azurerm_federated_identity_credentials → azurerm_federated_identity_credential
azurerm_container_registry_task → removed (use Trivy in pipeline)
purge_protection_enabled in features.key_vault → removed
AKS Free tier — no SLA, max 2 nodes recommended
Key Vault names are globally unique across all of Azure
B2s_v2 VMs are free for 12 months, then ~$38/mo each
License
MIT