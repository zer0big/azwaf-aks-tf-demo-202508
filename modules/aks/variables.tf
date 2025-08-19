variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "aks-zerobig"
}

# AKS 서브넷 ID (System/User) - main.tf에서 사용하는 이름과 일치시킴
variable "aks_system_subnet_id" {
  type = string
}

variable "aks_user_subnet_id" {
  type = string
}

# Service CIDR / DNS Service IP (필요 시 오버라이드 가능)
variable "service_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.0.0.10"
}

# AGIC 연동 및 ACR Pull에 사용
variable "appgw_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# 비용/성능 튜닝 파라미터
variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_node_count" {
  type    = number
  default = 1
}

variable "user_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "user_node_count" {
  type    = number
  default = 1
}

