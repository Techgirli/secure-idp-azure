variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "idp"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "admin_username" {
  description = "AKS admin username"
  type        = string
  default     = "idpadmin"
}

variable "vnet_cidr" {
  description = "VNet CIDR"
  type        = string
  default     = "172.16.0.0/16"
}

variable "node_subnet_cidr" {
  description = "Node subnet CIDR"
  type        = string
  default     = "172.16.1.0/24"
}

variable "system_subnet_cidr" {
  description = "System subnet CIDR"
  type        = string
  default     = "172.16.0.0/24"
}

variable "node_count" {
  description = "Number of node pool VMs"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for nodes (B2s_v2 is free for 12 months)"
  type        = string
  default     = "Standard_D2_v4"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}
