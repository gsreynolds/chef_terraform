variable "create_chef_ha" {
  description = "Create Chef Server in HA topology if true, standalone topology if false"
  default     = false
}

variable "deployment_name" {}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "ssh_whitelist_cidrs" {
  type        = "list"
  description = "List of CIDRs to allow SSH"
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {}

variable "zone_id" {}
variable "account_id" {}
