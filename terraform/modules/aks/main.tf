
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "kubernetes_version" { type = string }
variable "admin_username" { type = string }
variable "node_count" { type = number }
variable "node_vm_size" { type = string }
variable "vnet_subnet_id" { type = string }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "${var.prefix}-aks"
  sku_tier            = "Free"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    service_cidr        = "172.17.0.0/16"
    pod_cidr            = "172.18.0.0/16"
    dns_service_ip      = "172.17.0.10"
  }

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.vnet_subnet_id

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = false
    secret_rotation_interval = "2m"
  }
}

output "cluster_name" { value = azurerm_kubernetes_cluster.aks.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.aks.oidc_issuer_url }

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
