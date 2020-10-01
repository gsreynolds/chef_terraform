variable "instance_count" {
  default = 0
}

variable "ami" {
}

variable "ami_user" {
  type        = string
  description = "Default username"

  default = "ubuntu"
}

variable "default_tags" {
  type        = map(string)
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "chef_client_version" {
}

variable "az_subnet_ids" {
  type        = list(string)
  description = "Availability zone subnet IDs"
  default     = []
}

variable "ssh_security_group_id" {
}

variable "instance" {
  type        = map(string)
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

variable "hostnames" {
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    chef_client = "node"
  }
}

variable "instance_keys" {
  type        = map(string)
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

variable "zone_id" {
}

variable "r53_ttl" {
  type        = string
  description = "DNS record TTLS"

  default = "180"
}

variable "chef_admin" {
}

variable "chef_validator" {
}

variable "chef_server_fqdn" {
}

variable "unattended_registration_instance_profile" {
}

variable "server_ready" {
  type = list(string)

  default = []
}
