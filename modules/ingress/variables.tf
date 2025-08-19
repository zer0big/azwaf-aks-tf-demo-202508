variable "resource_group_name" {
  type        = string
  description = "Resource group name for ingress resources"
}

variable "location" {
  type        = string
  description = "Azure region (use short name like koreacentral)"
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default     = {}
}

variable "appgw_name" {
  type        = string
  description = "Application Gateway resource name"
  default     = "agw-zerobig"
}

variable "uai_name" {
  type        = string
  description = "User Assigned Identity name for Application Gateway"
  default     = "agw-uai"
}

variable "appgw_subnet_id" {
  type        = string
  description = "Subnet ID for Application Gateway (AppGatewaySubnet)"
}

variable "appgw_pip_name" {
  type        = string
  description = "Public IP resource name for Application Gateway"
  default     = "pip-agw-zerobig"
}

variable "kv_cert_secret_id" {
  type        = string
  description = "Key Vault secret ID (full URL) for the SSL cert. Leave empty to skip HTTPS."
  default     = ""
}

# autoscale 설정 변수(이미 main.tf에서 참조 중이면 필요)
variable "appgw_min_capacity" {
  type        = number
  description = "Minimum capacity for WAF_v2 autoscale"
  default     = 1
}

variable "appgw_max_capacity" {
  type        = number
  description = "Maximum capacity for WAF_v2 autoscale"
  default     = 2
}

