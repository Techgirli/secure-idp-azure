variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "vnet_cidr" { type = string }
variable "node_subnet_cidr" { type = string }
variable "system_subnet_cidr" { type = string }

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "system" {
  name                 = "${var.prefix}-subnet-system"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.system_subnet_cidr]
}

resource "azurerm_subnet" "node" {
  name                 = "${var.prefix}-subnet-node"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.node_subnet_cidr]
}

# NSG for node subnet — restrict inbound to SSH (22) and Kubernetes API (443) only
resource "azurerm_network_security_group" "node" {
  name                = "${var.prefix}-nsg-node"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-K8s-API"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Node-To-Node"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.1.0/24"
    destination_address_prefix = "172.16.1.0/24"
  }

  security_rule {
    name                       = "Allow-Node-To-Pod"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.1.0/24"
    destination_address_prefix = "172.18.0.0/16"
  }

  security_rule {
    name                       = "Allow-Pod-To-Pod"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.18.0.0/16"
    destination_address_prefix = "172.18.0.0/16"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "node" {
  subnet_id                 = azurerm_subnet.node.id
  network_security_group_id = azurerm_network_security_group.node.id
}

output "vnet_id" { value = azurerm_virtual_network.main.id }
output "node_subnet_id" { value = azurerm_subnet.node.id }
