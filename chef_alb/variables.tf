variable "deployment_name" {
}

variable "default_tags" {
  type        = map(string)
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
  description = "Chef ALB og bucket"
  default     = "chef-alb-logs"
}

variable "r53_ttl" {
  type        = string
  description = "DNS record TTLS"

  default = "180"
}

variable "zone_id" {
}

variable "account_id" {
}

variable "vpc_id" {
}

variable "https_security_group_id" {
}

variable "chef_target_count" {
  default = 0
}

variable "chef_target_ids" {
  type = list(string)

  default = []
}

variable "automate_target_ids" {
  type = list(string)

  default = []
}

variable "hostnames" {
  type        = map(string)
  description = "Instance hostname prefix"

  default = {
    chef_server     = "chef"
    automate_server = "automate"
  }
}

variable "domain" {
  description = "Zone domain name"
  default     = ""
}

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs"
  default     = []
}
