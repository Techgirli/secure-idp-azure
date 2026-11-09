variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "aks_oidc_issuer_url" { type = string }
variable "key_vault_id" { type = string }

resource "azurerm_user_assigned_identity" "vault_reader" {
  name                = "${var.prefix}-vault-reader"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "vault" {
  name                = "${var.prefix}-vault-federated"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.vault_reader.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:platform:vault-reader"
}

resource "azurerm_federated_identity_credential" "payments_staging" {
  name                = "${var.prefix}-payments-staging"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.vault_reader.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:staging:payments-api"
}

resource "azurerm_federated_identity_credential" "payments_production" {
  name                = "${var.prefix}-payments-production"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.vault_reader.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:production:payments-api"
}

resource "azurerm_role_assignment" "vault_data_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.vault_reader.principal_id
}

output "client_id" { value = azurerm_user_assigned_identity.vault_reader.client_id }
output "principal_id" { value = azurerm_user_assigned_identity.vault_reader.principal_id }
output "federated_credential_id" { value = azurerm_federated_identity_credential.vault.id }
