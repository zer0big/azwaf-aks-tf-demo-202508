variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "law_name" { type = string }

variable "target_ids" { type = map(string) }
variable "tags" { type = map(string) }

