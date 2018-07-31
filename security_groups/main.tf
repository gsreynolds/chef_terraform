# Security Groups
## SSH

resource "aws_security_group" "ssh" {
  name        = "${var.deployment_name} SSH SG"
  description = "${var.deployment_name} SSH SG"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} SSH SG"
    )
  )}"
}

resource "aws_security_group_rule" "restrict_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = "${var.ssh_whitelist_cidrs}"
  security_group_id = "${aws_security_group.ssh.id}"
}

resource "aws_security_group_rule" "allow_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.ssh.id}"
}

## Chef Automate & Chef Server
resource "aws_security_group" "https" {
  name        = "${var.deployment_name} HTTPS SG"
  description = "${var.deployment_name} HTTPS SG"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} HTTPS SG"
    )
  )}"
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.https.id}"
}

## Backend
resource "aws_security_group" "backend" {
  name        = "${var.deployment_name} Backend SG"
  description = "${var.deployment_name} Backend SG"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Backend SG"
    )
  )}"
}

resource "aws_security_group_rule" "backend_sg_all" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.backend.id}"
  security_group_id        = "${aws_security_group.backend.id}"
}

## etcd
resource "aws_security_group_rule" "backend_2379_tcp" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2379
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.https.id}"
  security_group_id        = "${aws_security_group.backend.id}"
}

## postgresql
resource "aws_security_group_rule" "backend_5432_tcp" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.https.id}"
  security_group_id        = "${aws_security_group.backend.id}"
}

## leaderl
resource "aws_security_group_rule" "backend_7331_tcp" {
  type                     = "ingress"
  from_port                = 7331
  to_port                  = 7331
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.https.id}"
  security_group_id        = "${aws_security_group.backend.id}"
}

## elasticsearch
resource "aws_security_group_rule" "backend_9200_tcp" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.https.id}"
  security_group_id        = "${aws_security_group.backend.id}"
}
