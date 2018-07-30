variable "deployment_name" {}

variable "ami" {}

variable "ami_user" {}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "subnet" {}

variable "ssh_security_group_id" {}
variable "https_security_group_id" {}

variable "instance" {
  type        = "map"
  description = "AWS Instance settings"

  default = {
    automate_server_flavor = "m5.large"
    automate_server_iops   = 0
    automate_server_public = true
    automate_server_size   = 40
    automate_server_term   = true
    automate_server_type   = "gp2"
    ebs_optimized          = true
  }
}

variable "instance_hostname" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    automate_server = "automate"
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
