
#!/bin/bash

# 1. Create Terraform state storage
az storage account create -n idptfstate001 -g idp-tfstate-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate -g idp-tfstate-rg --account-name idptfstate001

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Apply infrastructure
terraform apply -auto-approve

# 4. Get cluster credentials
az aks get-credentials -n idp-aks -g idp-rg --admin

# 5. Verify cluster
kubectl get nodes
kubectl get ns

# 6. Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml

# 7. Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set installCRDs=true

# 8. Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# 9. Apply constraints
kubectl apply -f ../platform/gatekeeper/constraints/

# 10. Apply default network policies
kubectl apply -f ../platform/network-policies/

# 11. Install Argo CD (if not done via Terraform)
helm install argocd argo/argo-cd -n argocd --create-namespace

# 12. Create namespaces
kubectl create ns staging
kubectl create ns production
kubectl create ns platform

# 13. Create ServiceAccount for vault-reader
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-reader
  namespace: platform
  annotations:
    azure.workload.identity/client-id: "$(terraform output workload_identity_client_id)"
EOF

# 14. Bootstrap Argo CD via GitOps
kubectl apply -f ../gitops/apps/argocd-bootstrap.yaml

# 15. Verify Argo CD is watching the repo
kubectl get applications -n argocd   
