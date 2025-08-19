variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "region_code" {
  type        = string
  description = "Region code without spaces and in lowercase (e.g., 'koreacentral')"
}

variable "hub_vnet_id" {
  type = string
}

variable "hub_pe_subnet_id" {
  type = string
}

variable "ingress_vnet_id" {
  type = string
}

variable "aks_vnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# 선택 입력: 값을 주면 그대로 사용, 안 주면 모듈이 자동 생성
variable "key_vault_name" {
  type    = string
  default = ""
}

variable "acr_name" {
  type    = string
  default = ""
}

