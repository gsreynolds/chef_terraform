variable "deployment_name" {}

variable "default_tags" {
  type        = "map"
  description = "Default resource tags"

  default = {
    X-Production = false
  }
}

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions#
variable "elb_account_id" {
  description = "Elastic Load Balancing Account ID for region eu-west-1"
  default     = "156460612806"
}

variable "log_bucket" {
  description = "Chef HA Log bucket"
  default     = "chef-ha-logs"
}

variable "r53_ttl" {
  type        = "string"
  description = "DNS record TTLS"

  default = "180"
}

variable "zone_id" {}
variable "account_id" {}
variable "vpc_id" {}
variable "https_security_group_id" {}

variable "target_ids" {
  type = "list"

  default = []
}

variable "frontend_hostname" {
  description = "Frontend ALB hostname name"
  default     = "chef"
}

variable "chef_target_count" {
  default = "1"
}

variable "domain" {
  description = "Zone domain name"
  default     = ""
}

variable "az_subnet_ids" {
  type        = "list"
  description = "Availability zone subnet IDs"
  default     = []
}
