variable "location" {
  type        = string
  description = "Azure region display name (e.g., 'Korea Central', 'East US 2')"
  default     = "Korea Central"
  # (선택) 오입력 방지용: 최소한 공백이 포함된 Display Name만 허용
  validation {
    condition     = can(regex("\\s", var.location))
    error_message = "Use the Azure region DISPLAY NAME (e.g., 'Korea Central'), not 'koreacentral'."
  }
}

variable "resource_group_name" {
  type    = string
  default = "rg-zerobig-platform"
}

variable "hub_vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "spoke_ingress_vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "spoke_aks_vnet_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "dns_zone_name" {
  type    = string
  default = "zerobig.kr"
}

variable "tags" {
  type = map(string)
  default = {
    env   = "dev"
    owner = "zerobig"
  }
}

variable "name_prefix" {
  type    = string
  default = "zerobig"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "randomize_names" {
  type    = bool
  default = true
}

