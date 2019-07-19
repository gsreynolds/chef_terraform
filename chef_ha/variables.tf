variable "create_chef_ha" {
  description = "Create Chef Server in HA topology if true, standalone topology if false"
  default     = true
}

variable "deployment_name" {}
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

variable "application_name" {
  description = "Application name"
  default     = "Chef HA"
}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "ssh_security_group_id" {}
variable "https_security_group_id" {}
variable "backend_security_group_id" {}

variable "vpc" {
  type        = "map"
  description = "VPC CIDR block"

  default = {
    cidr_block = ""
  }
}

variable "vpc_id" {}

variable "az_subnet_ids" {
  type        = "list"
  description = "Availability zone subnet IDs"
  default     = []
}

variable "ssh_whitelist_cidrs" {
  type        = "list"
  description = "List of CIDRs to allow SSH"
  default     = ["0.0.0.0/0"]
}

variable "domain" {
  description = "Zone domain name"
  default     = ""
}

variable "instance_keys" {
  type        = "map"
  description = ""

  default = {
    key_name = ""
    key_file = ""
  }
}

variable "instance" {
  type        = "map"
  description = "AWS Instance settings"

  default = {
    backend_flavor  = "m5.large"
    backend_iops    = 0
    backend_public  = true
    backend_size    = 40
    backend_term    = true
    backend_type    = "gp2"
    ebs_optimized   = true
    frontend_flavor = "m5.large"
    frontend_iops   = 0
    frontend_public = true
    frontend_size   = 40
    frontend_term   = true
    frontend_type   = "gp2"
  }
}

variable "hostnames" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    backend  = "chef-be"
    frontend = "chef-fe"
  }
}

variable "chef_backend" {
  type        = "map"
  description = "Chef backend settings"

  default = {
    count   = 3
    version = "2.0.1"
  }
}

variable "chef_frontend" {
  type        = "map"
  description = "Chef frontend settings"

  default = {
    count   = 3
    version = "12.19.31"
  }
}

variable "r53_ttl" {
  type        = "string"
  description = "DNS record TTLS"

  default = "180"
}

variable "zone_id" {}
variable "account_id" {}

variable automate_fqdn {}

variable "data_collector_token" {}
