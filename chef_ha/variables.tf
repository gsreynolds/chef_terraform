variable "create_chef_ha" {
  default = true
}

variable "deployment_name" {
}

variable "ami" {
}

variable "ami_user" {
  type        = string
  description = "Default username"

  default = "ubuntu"
}

variable "application_name" {
  description = "Application name"
  default     = "Chef HA"
}

variable "default_tags" {
  type        = map(string)
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "ssh_security_group_id" {
}

variable "https_security_group_id" {
}

variable "backend_security_group_id" {
}

variable "vpc" {
  type        = map(string)
  description = "VPC CIDR block"

  default = {
    cidr_block = ""
  }
}

variable "vpc_id" {
}

variable "az_subnet_ids" {
  type        = list(string)
  description = "Availability zone subnet IDs"
  default     = []
}

variable "ssh_whitelist_cidrs" {
  type        = list(string)
  description = "List of CIDRs to allow SSH"
  default     = ["0.0.0.0/0"]
}

variable "domain" {
  description = "Zone domain name"
  default     = ""
}

variable "instance_keys" {
  type        = map(string)
  description = ""

  default = {
    key_name = ""
    key_file = ""
  }
}

variable "instance" {
  type        = map(string)
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
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    backend  = "chef-be"
    frontend = "chef-fe"
  }
}

variable "chef_backend" {
  type        = map(string)
  description = "Chef backend settings"

  default = {
    count   = 3
    version = "2.0.30"
  }
}

variable "chef_frontend" {
  type        = map(string)
  description = "Chef frontend settings"

  default = {
    count   = 3
    version = "13.0.17"
  }
}

variable "r53_ttl" {
  type        = string
  description = "DNS record TTLS"

  default = "180"
}

variable "zone_id" {
}

variable "account_id" {
}

variable "automate_fqdn" {
}

variable "data_collector_token" {
}
