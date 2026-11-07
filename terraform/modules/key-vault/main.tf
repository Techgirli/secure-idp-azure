variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "prefix"              { type = string }
variable "tenant_id"           { type = string }

resource "azurerm_key_vault" "main" {
  name                = "${var.prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Use Azure RBAC (not Key Vault RBAC legacy)
  access_policy {
    # No static access policies — all access via Azure RBAC
  }
}

# Seed secrets (in production, use a pipeline or manual step)
resource "azurerm_key_vault_secret" "db_password" {
  name         = "payments-db-password"
  value        = "changeme-in-production"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "payments-api-key"
  value        = "changeme-in-production"
  key_vault_id = azurerm_key_vault.main.id
}

output "key_vault_id"   { value = azurerm_key_vault.main.id }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "key_vault_uri"  { value = azurerm_key_vault.main.vault_uri }   