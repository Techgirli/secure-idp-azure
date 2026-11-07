# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "secure-idp"
  }
}

# Network
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  prefix              = var.prefix
  vnet_cidr           = var.vnet_cidr
  node_subnet_cidr    = var.node_subnet_cidr
  system_subnet_cidr  = var.system_subnet_cidr
}

# AKS Cluster
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  prefix              = var.prefix
  kubernetes_version  = var.kubernetes_version
  admin_username      = var.admin_username
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  vnet_subnet_id      = module.network.node_subnet_id
}

# ACR
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  prefix              = var.prefix
}

# Key Vault
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  prefix              = var.prefix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  user_object_id      = data.azurerm_client_config.current.object_id
}   

# Workload Identity
module "workload_identity" {
  source = "./modules/workload-identity"

  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location
  prefix                  = var.prefix
  aks_oidc_issuer_url     = module.aks.oidc_issuer_url
  key_vault_id            = module.key_vault.key_vault_id
}

# Data sources
data "azurerm_client_config" "current" {}   
