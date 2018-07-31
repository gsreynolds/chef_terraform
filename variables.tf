variable "provider" {
  type        = "map"
  description = "AWS provider settings"

  default = {
    region  = ""
    profile = ""
  }
}

variable "application_name" {
  description = "Application name"
  default     = "Chef Automate"
}

variable "create_chef_ha" {
  description = "Create Chef Server in HA topology if true, standalone topology if false"
  default     = false
}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

variable "vpc" {
  type        = "map"
  description = "VPC CIDR block"

  default = {
    cidr_block = ""
  }
}

variable "az_subnets" {
  type        = "map"
  description = "Availability zone subnets"
  default     = {}
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

variable "ami_user" {
  type        = "string"
  description = "Default username"

  default = "ubuntu"
}

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
    backend_flavor         = "m5.large"
    backend_iops           = 0
    backend_public         = true
    backend_size           = 40
    backend_term           = true
    backend_type           = "gp2"
    chef_client_flavor     = "t2.medium"
    chef_client_iops       = 0
    chef_client_public     = true
    chef_client_size       = 10
    chef_client_term       = true
    chef_client_type       = "gp2"
    chef_server_flavor     = "m5.large"
    chef_server_iops       = 0
    chef_server_public     = true
    chef_server_size       = 40
    chef_server_term       = true
    chef_server_type       = "gp2"
    ebs_optimized          = true
    ebs_optimized          = true
    frontend_flavor        = "m5.large"
    frontend_iops          = 0
    frontend_public        = true
    frontend_size          = 40
    frontend_term          = true
    frontend_type          = "gp2"
  }
}

variable "instance_hostname" {
  type        = "map"
  description = "Instance hostname prefix"

  default = {
    chef_server     = "chef"
    automate_server = "automate"
    chef_client     = "node"
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

variable "r53_ttl" {
  type        = "string"
  description = "DNS record TTLS"

  default = "180"
}

variable "validator_key_path" {
  type        = "string"
  description = "Path to org validator key in SSM"

  default = "/chef/test/"
}

variable "frontend_hostname" {
  description = "Frontend ALB hostname name"
  default     = "chef"
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
    version = "12.17.33"
  }
}
