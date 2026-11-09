variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "tenant_id" { type = string }
variable "user_object_id" { type = string }

resource "azurerm_key_vault" "main" {
  name                       = "idp-kv-a7x3f2"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
}

# Grant the CLI user access to manage secrets
resource "azurerm_role_assignment" "vault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.user_object_id
}



output "key_vault_id" { value = azurerm_key_vault.main.id }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "key_vault_uri" { value = azurerm_key_vault.main.vault_uri }
