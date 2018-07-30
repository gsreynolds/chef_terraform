variable "deployment_name" {}

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
