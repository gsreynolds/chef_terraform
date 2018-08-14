variable "ami_user" {
  type        = "string"
  description = "Default username"

  default = "ubuntu"
}

variable "instance_keys" {
  type        = "map"
  description = ""

  default = {
    key_name = ""
    key_file = ""
  }
}

variable "chef_server_public_ip" {}
variable "automate_server_public_ip" {}

variable automate_fqdn {}

variable "chef_server_ids" {
  type = "list"

  default = []
}

variable "validator_key_path" {
  type        = "string"
  description = "Path to org validator key in SSM"

  default = "/chef/test/"
}

variable "data_collector_token" {}

variable "server_ready" {
  type = "list"

  default = []
}
