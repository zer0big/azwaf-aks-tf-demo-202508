location            = "Korea Central"
resource_group_name = "rg-zerobig-platform"
dns_zone_name       = "zerobig.kr" # 외부 레지스트라 사용 시에도 인그레스 Host 헤더 용도
tags = {
  env   = "demo"
  owner = "zerobig"
}

# AKS 노드 사이즈 (새 구독 비용 최적화)
user_vm_size = "Standard_B2s"

# (모듈이 random_id suffix를 이미 사용한다면 생략 가능)

