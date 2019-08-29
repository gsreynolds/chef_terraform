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

variable "subnet" {
}

variable "ssh_security_group_id" {
}

variable "https_security_group_id" {
}

variable "instance" {
  type        = map(string)
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

variable "hostnames" {
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    automate_server = "automate"
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

variable "automate_license" {
}
