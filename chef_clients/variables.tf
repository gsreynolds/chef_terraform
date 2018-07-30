variable "ami" {}
variable "ami_user" {}

variable "provider" {
  type        = "map"
  description = "AWS provider settings"

  default = {
    region  = ""
    profile = ""
  }
}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "az_subnet_ids" {
  type        = "list"
  description = "Availability zone subnet IDs"
  default     = []
}

variable "ssh_security_group_id" {}
variable "https_security_group_id" {}

variable "instance" {
  type        = "map"
  description = "AWS Instance settings"

  default = {
    ebs_optimized      = true
    chef_client_flavor = "t2.medium"
    chef_client_iops   = 0
    chef_client_public = true
    chef_client_size   = 10
    chef_client_term   = true
    chef_client_type   = "gp2"
  }
}

variable "instance_hostname" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    chef_client = "node"
  }
}

variable "instance_keys" {
  type        = "map"
  description = ""

  default = {
    key_name = ""
    key_file = ""
  }
}

variable "domain" {
  description = "Zone domain name"
  default     = ""
}

variable "zone_id" {}

variable "r53_ttl" {
  type        = "string"
  description = "DNS record TTLS"

  default = "180"
}

variable "validator_key_path" {}
variable "chef_server_fqdn" {}
variable "unattended_registration_instance_profile" {}
