variable "instance_count" {
  default = 0
}

variable "ami" {}

variable "ami_user" {
  type        = "string"
  description = "Default username"

  default = "ubuntu"
}

variable "aws_provider" {
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

variable "instance" {
  type        = "map"
  description = "AWS Instance settings"

  default = {
    ebs_optimized      = true
    effortless_client_flavor = "t2.medium"
    effortless_client_iops   = 0
    effortless_client_public = true
    effortless_client_size   = 10
    effortless_client_term   = true
    effortless_client_type   = "gp2"
  }
}

variable "hostnames" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    effortless_client = "effortless-node"
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
variable "automate_fqdn" {}
variable "origin" {}
variable "effortless_audit" {}
variable "effortless_config" {}

