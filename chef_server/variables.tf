variable "create_chef_server" {
  default = false
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

variable "default_tags" {
  type        = map(string)
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "chef_server_version" {
}

variable "ssh_security_group_id" {
}

variable "https_security_group_id" {
}

variable "subnet" {
}

variable "instance" {
  type        = map(string)
  description = "AWS Instance settings"

  default = {
    ebs_optimized      = true
    chef_server_flavor = "m5.large"
    chef_server_iops   = 0
    chef_server_public = true
    chef_server_size   = 40
    chef_server_term   = true
    chef_server_type   = "gp2"
  }
}

variable "hostnames" {
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    chef_server = "chef"
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

variable "automate_fqdn" {
}

variable "data_collector_token" {
}
