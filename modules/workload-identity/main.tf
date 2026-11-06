variable "resource_group_name"     { type = string }
variable "location"                { type = string }
variable "prefix"                  { type = string }
variable "aks_oidc_issuer_url"     { type = string }
variable "key_vault_id"            { type = string }
variable "tenant_id"               { type = string }

# User-Assigned Managed Identity for Key Vault access
resource "azurerm_user_assigned_identity" "vault_reader" {
  name                = "${var.prefix}-vault-reader"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Federated Identity Credential: links K8s ServiceAccount → Managed Identity
resource "azurerm_federated_identity_credentials" "vault" {
  name                   = "${var.prefix}-vault-federated"
  identity_client_id     = azurerm_user_assigned_identity.vault_reader.client_id
  issuer                 = var.aks_oidc_issuer_url
  subject                = "system:serviceaccount:platform:vault-reader"
  audiences              = ["api://AzureADTokenExchange"]
}

# Role Assignment: grant Key Vault Secrets Data Reader to the identity
resource "azurerm_role_assignment" "vault_data_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Data Reader"
  principal_id         = azurerm_user_assigned_identity.vault_reader.principal_id
}

output "client_id"                { value = azurerm_user_assigned_identity.vault_reader.client_id }
output "principal_id"             { value = azurerm_user_assigned_identity.vault_reader.principal_id }
output "federated_credential_id"  { value = azurerm_federated_identity_credentials.vault.id }   