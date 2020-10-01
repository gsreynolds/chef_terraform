variable "validator_key_path" {
  type        = string
  description = "Path to org validator key in SSM"

  default = "/chef/test/"
}

variable "account_id" {
}

variable "create_unattended_registration" {
}
