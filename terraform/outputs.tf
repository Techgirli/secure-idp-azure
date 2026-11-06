output "cluster_name" {
  value = module.aks.cluster_name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_name" {
  value = module.key_vault.key_vault_name
}

output "workload_identity_client_id" {
  value = module.workload_identity.client_id
}

output "workload_identity_federated_credential_id" {
  value = module.workload_identity.federated_credential_id
}

output "vnet_id" {
  value = module.network.vnet_id
}   