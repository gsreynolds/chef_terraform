provider "aws" {}

locals {
  deployment_name = var.application_name
}

data "local_file" "automate_license" {
  filename = "automate.license"
}

data "aws_caller_identity" "current" {
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
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

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/1.37.0
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.deployment_name
  cidr = var.vpc["cidr_block"]

  azs = keys(var.az_subnets)

  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = values(var.az_subnets)

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  tags = var.default_tags
}

module "security_groups" {
  source = "./security_groups"

  create_chef_ha = var.create_chef_ha

  account_id          = data.aws_caller_identity.current.account_id
  default_tags        = var.default_tags
  deployment_name     = local.deployment_name
  ssh_whitelist_cidrs = var.ssh_whitelist_cidrs
  vpc_id              = module.vpc.vpc_id
  zone_id             = data.aws_route53_zone.zone.id
}

module "chef_automate2" {
  source = "./chef_automate2"

  ami                     = data.aws_ami.ubuntu.id
  ami_user                = var.ami_user
  automate_fqdn           = module.chef_alb.automate_alb_fqdn
  automate_license        = chomp(data.local_file.automate_license.content)
  default_tags            = var.default_tags
  deployment_name         = local.deployment_name
  domain                  = var.domain
  https_security_group_id = module.security_groups.https_security_group_id
  instance                = var.instance
  hostnames               = var.hostnames
  instance_keys           = var.instance_keys
  r53_ttl                 = var.r53_ttl
  ssh_security_group_id   = module.security_groups.ssh_security_group_id
  subnet                  = element(module.vpc.public_subnets, 1 % length(keys(var.az_subnets)))
  zone_id                 = data.aws_route53_zone.zone.id
}

module "chef_server" {
  source = "./chef_server"

  create_chef_server = var.create_chef_server

  ami                     = data.aws_ami.ubuntu.id
  ami_user                = var.ami_user
  automate_fqdn           = module.chef_alb.automate_alb_fqdn
  chef_server_version     = var.chef_frontend["version"]
  data_collector_token    = module.chef_automate2.data_collector_token
  default_tags            = var.default_tags
  deployment_name         = local.deployment_name
  domain                  = var.domain
  hostnames               = var.hostnames
  https_security_group_id = module.security_groups.https_security_group_id
  instance                = var.instance
  instance_keys           = var.instance_keys
  r53_ttl                 = var.r53_ttl
  ssh_security_group_id   = module.security_groups.ssh_security_group_id
  subnet                  = element(module.vpc.public_subnets, 1 % length(keys(var.az_subnets)))
  zone_id                 = data.aws_route53_zone.zone.id
}

module "chef_ha" {
  source = "./chef_ha"

  create_chef_ha = var.create_chef_ha

  account_id                = data.aws_caller_identity.current.account_id
  ami                       = data.aws_ami.ubuntu.id
  ami_user                  = var.ami_user
  automate_fqdn             = module.chef_alb.automate_alb_fqdn
  az_subnet_ids             = module.vpc.public_subnets
  backend_security_group_id = module.security_groups.backend_security_group_id
  chef_backend              = var.chef_backend
  chef_frontend             = var.chef_frontend
  data_collector_token      = module.chef_automate2.data_collector_token
  default_tags              = var.default_tags
  deployment_name           = local.deployment_name
  domain                    = var.domain
  hostnames                 = var.hostnames
  https_security_group_id   = module.security_groups.https_security_group_id
  instance                  = var.instance
  instance_keys             = var.instance_keys
  ssh_security_group_id     = module.security_groups.ssh_security_group_id
  vpc                       = var.vpc
  vpc_id                    = module.vpc.vpc_id
  zone_id                   = data.aws_route53_zone.zone.id
}

module "chef_alb" {
  source = "./chef_alb"

  account_id              = data.aws_caller_identity.current.account_id
  subnets                 = module.vpc.public_subnets
  deployment_name         = local.deployment_name
  domain                  = var.domain
  hostnames               = var.hostnames
  https_security_group_id = module.security_groups.https_security_group_id
  log_bucket              = var.log_bucket
  chef_target_ids = concat(
    module.chef_ha.frontend_ids,
    module.chef_server.chef_server_id,
  )
  chef_target_count   = var.create_chef_ha ? var.chef_frontend["count"] : 1
  automate_target_ids = module.chef_automate2.chef_automate_ids
  vpc_id              = module.vpc.vpc_id
  zone_id             = data.aws_route53_zone.zone.id
}

module "chef_unattended_registration" {
  source = "./chef_unattended_registration"

  create_unattended_registration = var.create_chef_ha || var.create_chef_server ? 1 : 0

  account_id         = data.aws_caller_identity.current.account_id
  validator_key_path = var.validator_key_path
}

module "test_org_setup" {
  source = "./test_org_setup"

  create_test_org = var.create_chef_ha || var.create_chef_server ? 1 : 0

  # server_ready is an inter-module dependency workaround to ensure that the org doesn't get created until chef server/all front ends are configured
  server_ready = concat(
    module.chef_ha.data_collector_configured,
    module.chef_server.data_collector_configured,
  )

  ami_user                  = var.ami_user
  automate_fqdn             = module.chef_alb.automate_alb_fqdn
  chef_server_fqdn          = module.chef_alb.chef_alb_fqdn
  automate_server_public_ip = element(module.chef_automate2.chef_automate_public_ip, 0)
  chef_server_ids = concat(
    module.chef_ha.frontend_ids,
    module.chef_server.chef_server_id,
  )
  chef_server_public_ip = concat(
    module.chef_ha.chef_server_public_ip,
    module.chef_server.chef_server_public_ip,
  )
  data_collector_token = module.chef_automate2.data_collector_token
  instance_keys        = var.instance_keys
  validator_key_path   = var.validator_key_path
}

module "chef_clients" {
  source = "./chef_clients"

  # server_ready is an inter-module dependency workaround to ensure that the clients don't get created until chef server and alb is created
  server_ready = concat(
    module.chef_ha.data_collector_configured,
    module.chef_server.data_collector_configured,
    [
      # module.chef_alb.forward_to_chef_rule_id,
      # module.chef_alb.forward_to_automate_rule_id,
      module.chef_automate2.a2_url
    ]
  )

  ami                                      = data.aws_ami.ubuntu.id
  ami_user                                 = var.ami_user
  az_subnet_ids                            = module.vpc.public_subnets
  chef_client_version                      = var.chef_clients["version"]
  chef_server_fqdn                         = module.chef_alb.chef_alb_fqdn
  chef_admin                               = module.test_org_setup.chef_admin
  chef_validator                           = module.test_org_setup.test_chef_validator
  instance_count                           = var.chef_clients["count"]
  default_tags                             = var.default_tags
  domain                                   = var.domain
  hostnames                                = var.hostnames
  instance                                 = var.instance
  instance_keys                            = var.instance_keys
  r53_ttl                                  = var.r53_ttl
  ssh_security_group_id                    = module.security_groups.ssh_security_group_id
  unattended_registration_instance_profile = module.chef_unattended_registration.instance_profile
  zone_id                                  = data.aws_route53_zone.zone.id
}

module "effortless_clients" {
  source = "./effortless_clients"

  # server_ready is an inter-module dependency workaround to ensure that the clients don't get created until chef server and alb is created
  server_ready = concat(
    module.chef_ha.data_collector_configured,
    module.chef_server.data_collector_configured,
    [
      # module.chef_alb.forward_to_chef_rule_id,
      # module.chef_alb.forward_to_automate_rule_id,
      module.chef_automate2.a2_url
    ]
  )

  ami                   = data.aws_ami.ubuntu.id
  ami_user              = var.ami_user
  az_subnet_ids         = module.vpc.public_subnets
  origin                = var.effortless_clients["origin"]
  effortless_audit      = var.effortless_clients["effortless_audit"]
  effortless_config     = var.effortless_clients["effortless_config"]
  automate_fqdn         = module.chef_alb.automate_alb_fqdn
  instance_count        = var.effortless_clients["count"]
  data_collector_token  = module.chef_automate2.data_collector_token
  default_tags          = var.default_tags
  domain                = var.domain
  hostnames             = var.hostnames
  instance              = var.instance
  instance_keys         = var.instance_keys
  r53_ttl               = var.r53_ttl
  ssh_security_group_id = module.security_groups.ssh_security_group_id
  zone_id               = data.aws_route53_zone.zone.id
}
