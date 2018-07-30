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
module "vpc" {
  source          = "./vpc"
  default_tags    = "${var.default_tags}"
  az_subnets      = "${var.az_subnets}"
  vpc             = "${var.vpc}"
  deployment_name = "${local.deployment_name}"
}

module "security_groups" {
  source              = "./security_groups"
  default_tags        = "${var.default_tags}"
  ssh_whitelist_cidrs = "${var.ssh_whitelist_cidrs}"
  vpc_id              = "${module.vpc.vpc_id}"
  deployment_name     = "${local.deployment_name}"
}

module "chef_automate2" {
  source = "./chef_automate2"

  ami                     = "${data.aws_ami.ubuntu.id}"
  ami_user                = "${var.ami_user}"
  default_tags            = "${var.default_tags}"
  instance                = "${var.instance}"
  instance_keys           = "${var.instance_keys}"
  instance_hostname       = "${var.instance_hostname}"
  domain                  = "${var.domain}"
  zone_id                 = "${data.aws_route53_zone.zone.id}"
  subnet                  = "${element(module.vpc.subnet_ids, 1 % length(keys(var.az_subnets)))}"
  ssh_security_group_id   = "${module.security_groups.ssh_security_group_id}"
  https_security_group_id = "${module.security_groups.https_security_group_id}"
  deployment_name         = "${local.deployment_name}"
  r53_ttl                 = "${var.r53_ttl}"
}

module "chef_server" {
  source = "./chef_server"

  ami                     = "${data.aws_ami.ubuntu.id}"
  ami_user                = "${var.ami_user}"
  default_tags            = "${var.default_tags}"
  instance                = "${var.instance}"
  instance_keys           = "${var.instance_keys}"
  instance_hostname       = "${var.instance_hostname}"
  domain                  = "${var.domain}"
  zone_id                 = "${data.aws_route53_zone.zone.id}"
  subnet                  = "${element(module.vpc.subnet_ids, 1 % length(keys(var.az_subnets)))}"
  ssh_security_group_id   = "${module.security_groups.ssh_security_group_id}"
  https_security_group_id = "${module.security_groups.https_security_group_id}"
  deployment_name         = "${local.deployment_name}"
  r53_ttl                 = "${var.r53_ttl}"
}

module "chef_ha" {
  source = "./chef_ha"

  # ami          = "${data.aws_ami.ubuntu.id}"
  # default_tags = "${var.default_tags}"
  # instance_keys = "${var.instance_keys}"
  # domain        = "${var.domain}"
  # zone_id       = "${data.aws_route53_zone.zone.id}"
  # az_subnets    = "${var.az_subnets}"
}

module "chef_clients" {
  source = "./chef_clients"

  ami                                      = "${data.aws_ami.ubuntu.id}"
  ami_user                                 = "${var.ami_user}"
  default_tags                             = "${var.default_tags}"
  instance                                 = "${var.instance}"
  instance_keys                            = "${var.instance_keys}"
  instance_hostname                        = "${var.instance_hostname}"
  domain                                   = "${var.domain}"
  zone_id                                  = "${data.aws_route53_zone.zone.id}"
  az_subnet_ids                            = "${module.vpc.subnet_ids}"
  ssh_security_group_id                    = "${module.security_groups.ssh_security_group_id}"
  https_security_group_id                  = "${module.security_groups.https_security_group_id}"
  validator_key_path                       = "${var.validator_key_path}"
  provider                                 = "${var.provider}"
  chef_server_fqdn                         = "${module.chef_server.chef_server_fqdn}"
  unattended_registration_instance_profile = "${module.chef_unattended_registration.instance_profile}"
  r53_ttl                                  = "${var.r53_ttl}"
}

module "chef_unattended_registration" {
  source = "./chef_unattended_registration"

  provider           = "${var.provider}"
  account_id         = "${data.aws_caller_identity.current.account_id}"
  validator_key_path = "${var.validator_key_path}"
}
