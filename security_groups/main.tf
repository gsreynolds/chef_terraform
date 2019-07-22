# Security Groups
## SSH
module "ssh_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ssh"
  description = "Security group for SSH-in and egress"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = var.ssh_whitelist_cidrs
  ingress_rules       = ["ssh-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} SSH SG"
    },
  )
}

## Chef Automate & Chef Server/Chef HA Frontends
module "https_all_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "https"
  description = "Security group for HTTPS-in from all to all"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} HTTPS-all SG"
    },
  )
}

## Backend
module "backend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  create = var.create_chef_ha ? true : false

  name        = "backend"
  description = "Security group for Chef HA backend"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      # permit all to all from other backends
      rule                     = "all-all"
      source_security_group_id = module.backend_sg.this_security_group_id
    },
    {
      ## etcd from frontends
      from_port                = 2379
      to_port                  = 2379
      protocol                 = "tcp"
      source_security_group_id = module.https_all_sg.this_security_group_id
    },
    {
      ## postgresql from frontends
      rule                     = "postgresql-tcp"
      source_security_group_id = module.https_all_sg.this_security_group_id
    },
    {
      ## leaderl from frontends
      from_port                = 7331
      to_port                  = 7331
      protocol                 = "tcp"
      source_security_group_id = module.https_all_sg.this_security_group_id
    },
    {
      ## elasticsearch from frontends
      rule                     = "elasticsearch-rest-tcp"
      source_security_group_id = module.https_all_sg.this_security_group_id
    },
  ]

  number_of_computed_ingress_with_source_security_group_id = 5

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} Backend SG"
    },
  )
}
