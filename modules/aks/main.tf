variable "resource_group_name"  { type = string }
variable "location"             { type = string }
variable "prefix"               { type = string }
variable "kubernetes_version"   { type = string }
variable "admin_username"       { type = string }
variable "node_count"           { type = number }
variable "node_vm_size"         { type = string }
variable "vnet_subnet_id"       { type = string }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "${var.prefix}-aks"

  # FREE TIER — $0 control plane, no SLA
  sku_tier = "Free"

  # Identity & Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_rbac_enabled        = true

  # Network
  network_plugin          = "azure"
  network_plugin_mode     = "Overlay"
  network_policy          = "calico"
  default_node_pool {
    name         = "system"
    node_count   = var.node_count
    vm_size      = var.node_vm_size
    vnet_subnet_id = var.vnet_subnet_id
  }

  # Enable Key Vault CSI Driver addon
  addon_profiles {
    azure_keyvault_secrets_provider {
      enabled = true
    }
  }

  # Disable public access to API server (use private endpoint or jumpbox)
  # For dev: keep public for simplicity
  api_server_authorized_ip_ranges = []

  identity {
    type = "SystemAssigned"
  }

  tags = {
    tier = "free"
  }
}

# Attach ACR to AKS (pull images without credentials)
resource "azurerm_kubernetes_cluster" "aks" {
  # ... (same as above)
}

output "cluster_name"      { value = azurerm_kubernetes_cluster.aks.name }
output "oidc_issuer_url"   { value = azurerm_kubernetes_cluster.aks.oidc_issuer_url }
output "kube_config_raw"   { value = azurerm_kubernetes_cluster.aks.kube_config_raw }
output "node_resource_group" { value = azurerm_kubernetes_cluster.aks.node_resource_group_name }   