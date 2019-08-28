variable "validator_key_path" {
  type        = "string"
  description = "Path to org validator key in SSM"

  default = "/chef/test/"
}

variable "aws_provider" {
  type        = "map"
  description = "AWS provider settings"

  default = {
    region  = ""
    profile = ""
  }
}

variable "account_id" {}
variable "create_unattended_registration" {}
