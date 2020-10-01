variable "application_name" {
  description = "Application name"
  default     = "Chef Automate"
}

variable "create_chef_server" {
  description = "Create Chef Server in standalone topology"
  default     = false
}

variable "create_chef_ha" {
  description = "Create Chef Server in HA topology if true"
  default     = false
}

variable "default_tags" {
  type        = map(string)
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "vpc" {
  type        = map(string)
  description = "VPC CIDR block"

  default = {
    cidr_block = ""
  }
}

variable "az_subnets" {
  type        = map(string)
  description = "Availability zone subnets"
  default     = {}
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

variable "ami_user" {
  type        = string
  description = "Default username"

  default = "ubuntu"
}

variable "instance" {
  type        = map(string)
  description = "AWS Instance settings"

  default = {
    automate_server_flavor   = "m5.large"
    automate_server_iops     = 0
    automate_server_public   = true
    automate_server_size     = 40
    automate_server_term     = true
    automate_server_type     = "gp2"
    backend_flavor           = "m5.large"
    backend_iops             = 0
    backend_public           = true
    backend_size             = 40
    backend_term             = true
    backend_type             = "gp2"
    chef_client_flavor       = "t2.medium"
    chef_client_iops         = 0
    chef_client_public       = true
    chef_client_size         = 10
    chef_client_term         = true
    chef_client_type         = "gp2"
    effortless_client_flavor = "t2.medium"
    effortless_client_iops   = 0
    effortless_client_public = true
    effortless_client_size   = 10
    effortless_client_term   = true
    effortless_client_type   = "gp2"
    chef_server_flavor       = "m5.large"
    chef_server_iops         = 0
    chef_server_public       = true
    chef_server_size         = 40
    chef_server_term         = true
    chef_server_type         = "gp2"
    ebs_optimized            = true
    ebs_optimized            = true
    frontend_flavor          = "m5.large"
    frontend_iops            = 0
    frontend_public          = true
    frontend_size            = 40
    frontend_term            = true
    frontend_type            = "gp2"
  }
}

variable "hostnames" {
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    chef_server       = "chef"
    automate_server   = "automate"
    chef_client       = "node"
    effortless_client = "effortless-node"
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

variable "r53_ttl" {
  type        = string
  description = "DNS record TTLS"

  default = "180"
}

variable "validator_key_path" {
  type        = string
  description = "Path to org validator key in SSM"

  default = "/chef/test/"
}

variable "chef_backend" {
  type = object({
    count   = number
    version = string
  })
  description = "Chef backend settings"

  default = {
    count   = 3
    version = "2.0.30"
  }
}

variable "chef_frontend" {
  type = object({
    count   = number
    version = string
  })
  description = "Chef frontend settings"

  default = {
    count   = 3
    version = "13.0.17"
  }
}

variable "chef_clients" {
  type = object({
    count   = number
    version = string
  })
  description = "Chef Client settings"

  default = {
    count   = 0
    version = "15.2.20"
  }
}

variable "effortless_clients" {
  type = object({
    count             = number
    origin            = string
    effortless_audit  = string
    effortless_config = string
  })
  description = "Effortless Client settings"

  default = {
    count             = 0
    origin            = "gsreynolds"
    effortless_audit  = "inspec-linux-audit"
    effortless_config = "linux-hardening"
  }
}

variable "log_bucket" {
  description = "Chef HA Log bucket"
  default     = "chef-ha-logs"
}

