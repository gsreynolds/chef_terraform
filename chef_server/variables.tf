variable "create_chef_ha" {
  description = "Create Chef Server in HA topology if true, standalone topology if false"
  default     = false
}

variable "deployment_name" {}
variable "ami" {}

variable "ami_user" {
  type        = "string"
  description = "Default username"

  default = "ubuntu"
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

variable "subnet" {}

variable "instance" {
  type        = "map"
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

variable "instance_hostname" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    chef_server = "chef"
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
