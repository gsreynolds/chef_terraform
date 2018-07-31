provider "aws" {
  region  = "${var.provider["region"]}"
  profile = "${var.provider["profile"]}"
}

locals {
  deployment_name = "${var.application_name}"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_route53_zone" "zone" {
  name         = "${var.domain}."
  private_zone = false
}

# ==========
# module "vpc" {
#   source          = "./vpc"
#   default_tags    = "${var.default_tags}"
#   az_subnets      = "${var.az_subnets}"
#   vpc             = "${var.vpc}"
#   deployment_name = "${local.deployment_name}"
# }

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.37.0
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.deployment_name}"
  cidr = "10.0.0.0/16"

  azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  tags = "${var.default_tags}"
}

module "security_groups" {
  source = "./security_groups"

  account_id          = "${data.aws_caller_identity.current.account_id}"
  default_tags        = "${var.default_tags}"
  deployment_name     = "${local.deployment_name}"
  ssh_whitelist_cidrs = "${var.ssh_whitelist_cidrs}"
  vpc_id              = "${module.vpc.vpc_id}"
  zone_id             = "${data.aws_route53_zone.zone.id}"
}

module "chef_automate2" {
  source = "./chef_automate2"

  ami                     = "${data.aws_ami.ubuntu.id}"
  ami_user                = "${var.ami_user}"
  default_tags            = "${var.default_tags}"
  deployment_name         = "${local.deployment_name}"
  domain                  = "${var.domain}"
  https_security_group_id = "${module.security_groups.https_security_group_id}"
  instance                = "${var.instance}"
  instance_hostname       = "${var.instance_hostname}"
  instance_keys           = "${var.instance_keys}"
  r53_ttl                 = "${var.r53_ttl}"
  ssh_security_group_id   = "${module.security_groups.ssh_security_group_id}"
  subnet                  = "${element(module.vpc.public_subnets, 1 % length(keys(var.az_subnets)))}"
  zone_id                 = "${data.aws_route53_zone.zone.id}"
}

module "chef_server" {
  source = "./chef_server"

  ami                     = "${data.aws_ami.ubuntu.id}"
  ami_user                = "${var.ami_user}"
  default_tags            = "${var.default_tags}"
  deployment_name         = "${local.deployment_name}"
  domain                  = "${var.domain}"
  https_security_group_id = "${module.security_groups.https_security_group_id}"
  instance                = "${var.instance}"
  instance_hostname       = "${var.instance_hostname}"
  instance_keys           = "${var.instance_keys}"
  r53_ttl                 = "${var.r53_ttl}"
  ssh_security_group_id   = "${module.security_groups.ssh_security_group_id}"
  subnet                  = "${element(module.vpc.public_subnets, 1 % length(keys(var.az_subnets)))}"
  zone_id                 = "${data.aws_route53_zone.zone.id}"
}

module "chef_ha" {
  source = "./chef_ha"

  account_id                = "${data.aws_caller_identity.current.account_id}"
  ami                       = "${data.aws_ami.ubuntu.id}"
  ami_user                  = "${var.ami_user}"
  az_subnet_ids             = "${module.vpc.public_subnets}"
  backend_security_group_id = "${module.security_groups.backend_security_group_id}"
  default_tags              = "${var.default_tags}"
  deployment_name           = "${local.deployment_name}"
  domain                    = "${var.domain}"
  https_security_group_id   = "${module.security_groups.https_security_group_id}"
  instance                  = "${var.instance}"
  instance_keys             = "${var.instance_keys}"
  ssh_security_group_id     = "${module.security_groups.ssh_security_group_id}"
  vpc_id                    = "${module.vpc.vpc_id}"
  zone_id                   = "${data.aws_route53_zone.zone.id}"
}

module "chef_clients" {
  source = "./chef_clients"

  ami                                      = "${data.aws_ami.ubuntu.id}"
  ami_user                                 = "${var.ami_user}"
  az_subnet_ids                            = "${module.vpc.public_subnets}"
  chef_server_fqdn                         = "${module.chef_server.chef_server_fqdn}"
  default_tags                             = "${var.default_tags}"
  domain                                   = "${var.domain}"
  https_security_group_id                  = "${module.security_groups.https_security_group_id}"
  instance                                 = "${var.instance}"
  instance_hostname                        = "${var.instance_hostname}"
  instance_keys                            = "${var.instance_keys}"
  provider                                 = "${var.provider}"
  r53_ttl                                  = "${var.r53_ttl}"
  ssh_security_group_id                    = "${module.security_groups.ssh_security_group_id}"
  unattended_registration_instance_profile = "${module.chef_unattended_registration.instance_profile}"
  validator_key_path                       = "${var.validator_key_path}"
  zone_id                                  = "${data.aws_route53_zone.zone.id}"
}

module "chef_unattended_registration" {
  source = "./chef_unattended_registration"

  account_id         = "${data.aws_caller_identity.current.account_id}"
  provider           = "${var.provider}"
  validator_key_path = "${var.validator_key_path}"
}
