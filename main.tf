########################################
# 이름 접미사(전역 유니크 회피) & 로컬 네이밍
########################################
resource "random_id" "suffix" {
  byte_length = 2 # 4-hex
}

locals {
  # 하이픈 포함 접미사 (대부분 리소스)
  suffix = var.randomize_names ? "-${random_id.suffix.hex}" : ""

  region_code = lower(replace(var.location, " ", ""))

  # ACR 전용: 하이픈 불가/영문소문자+숫자만 -> env 또는 hex 사용
  acr_suffix = var.randomize_names ? random_id.suffix.hex : var.env

  # 최종 이름들
  rg_name = "${var.resource_group_name}${local.suffix}"

  hub_vnet_name     = "vnet-${var.name_prefix}-hub${local.suffix}"
  ingress_vnet_name = "vnet-${var.name_prefix}-ingress${local.suffix}"
  aks_vnet_name     = "vnet-${var.name_prefix}-aks${local.suffix}"

  kv_name = "kv-${var.name_prefix}${local.suffix}"
  # ACR: 전역 유니크 + 제약 준수
  acr_name = lower(replace("acr${var.name_prefix}${local.acr_suffix}", "[^a-z0-9]", ""))

  law_name = "law-${var.name_prefix}-platform${local.suffix}"

  agw_name = "agw-${var.name_prefix}${local.suffix}"
  pip_name = "pip-agw-${var.name_prefix}${local.suffix}"
  uai_name = "agw-uai${local.suffix}"
}

########################################
# 리소스 그룹
########################################
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

########################################
# 네트워킹 모듈
########################################
module "networking" {
  source              = "./modules/networking"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  hub_vnet_name     = local.hub_vnet_name
  ingress_vnet_name = local.ingress_vnet_name
  aks_vnet_name     = local.aks_vnet_name

  hub_vnet_cidr           = var.hub_vnet_cidr
  spoke_ingress_vnet_cidr = var.spoke_ingress_vnet_cidr
  spoke_aks_vnet_cidr     = var.spoke_aks_vnet_cidr
  tags                    = var.tags
}

########################################
# 시큐리티 모듈 (Key Vault / ACR / Private DNS / PE)
########################################
module "security" {
  source              = "./modules/security"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  region_code         = local.region_code

  # Hub의 MgmtSubnet을 Private Endpoint 용도로 전달
  hub_vnet_id      = module.networking.hub_vnet_id
  hub_pe_subnet_id = module.networking.hub_mgmt_subnet_id

  aks_vnet_id     = module.networking.aks_vnet_id
  ingress_vnet_id = module.networking.ingress_vnet_id

  tags = var.tags
}

########################################
# 인그레스 모듈 (AppGW/WAF + UAI + PIP)
########################################
module "ingress" {
  source              = "./modules/ingress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  appgw_name = local.agw_name

  # 서브넷/연계
  appgw_subnet_id = module.networking.appgw_subnet_id
  # (옵션) KV 인증서 시크릿 ID를 Terraform로 주입하려면 여기에 변수 연결
  # kv_cert_secret_id = "<KeyVault Secret full ID>"

  tags = var.tags
}

########################################
# 모니터링 모듈 (LAW + 진단 설정)
########################################
module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  law_name = local.law_name

  # 진단 대상 리소스
  target_ids = {
    firewall = module.networking.firewall_id
    appgw    = module.ingress.appgw_id
  }

  tags = var.tags
}

########################################
# AKS 모듈 
########################################
module "aks" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  # 지우면 기본값 사용, 줄을 남기면 명시적으로 이름 지정
  cluster_name = "aks-zerobig"

  aks_system_subnet_id = module.networking.aks_system_subnet_id
  aks_user_subnet_id   = module.networking.aks_user_subnet_id

  # AGIC / ACR 연동
  appgw_id = module.ingress.appgw_id
  acr_id   = module.security.acr_id

  # 서비스 CIDR/DNS는 모듈 기본값 사용 (필요 시 아래 주석 해제)
  # service_cidr   = "10.0.0.0/16"
  # dns_service_ip = "10.0.0.10"

  tags = var.tags
}


