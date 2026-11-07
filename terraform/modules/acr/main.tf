variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "prefix"              { type = string }

resource "azurerm_container_registry" "acr" {
  name                = "reg${replace(var.prefix, "-", "")}${substr(md5(var.prefix), 0, 6)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  admin_enabled       = false
}

output "login_server" { value = azurerm_container_registry.acr.login_server }
output "id"           { value = azurerm_container_registry.acr.id }   
