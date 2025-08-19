variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "hub_vnet_name" {
  type = string
}

variable "ingress_vnet_name" {
  type = string
}

variable "aks_vnet_name" {
  type = string
}

variable "hub_vnet_cidr" {
  type = string
}

variable "spoke_ingress_vnet_cidr" {
  type = string
}

variable "spoke_aks_vnet_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}

