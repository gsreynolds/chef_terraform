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
  name        = "${var.deployment_name} Chef Automate SG"
  description = "${var.deployment_name} Chef Automate SG"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Chef Automate SG"
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
