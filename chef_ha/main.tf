locals {
  alb_fqdn = "${var.frontend_hostname}.${var.domain}"
}

# Instances

resource "aws_instance" "backends" {
  count                       = "${var.create_chef_ha ? var.chef_backend["count"] : 0}"
  ami                         = "${var.ami}"
  ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = "${var.instance["backend_flavor"]}"
  associate_public_ip_address = "${var.instance["backend_public"]}"
  subnet_id                   = "${element(var.az_subnet_ids, count.index)}"
  vpc_security_group_ids      = ["${var.backend_security_group_id}", "${var.ssh_security_group_id}"]
  key_name                    = "${var.instance_keys["key_name"]}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["backend"], count.index + 1, var.domain)}"
    )
  )}"

  root_block_device {
    delete_on_termination = "${var.instance["backend_term"]}"
    volume_size           = "${var.instance["backend_size"]}"
    volume_type           = "${var.instance["backend_type"]}"
    iops                  = "${var.instance["backend_iops"]}"
  }

  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y ntp",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-backend -d /tmp -v ${var.chef_backend["version"]}",
      "echo 'publish_address \"${self.private_ip}\"'|sudo tee -a /etc/chef-backend/chef-backend.rb",
      "echo 'postgresql.md5_auth_cidr_addresses = [\"samehost\",\"samenet\",\"${var.vpc["cidr_block"]}\"]'|sudo tee -a /etc/chef-backend/chef-backend.rb",
    ]
  }
}

resource "aws_eip" "backends" {
  vpc      = true
  count    = "${var.create_chef_ha ? var.chef_backend["count"] : 0}"
  instance = "${element(aws_instance.backends.*.id, count.index)}"

  # depends_on = ["aws_internet_gateway.main"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["backend"], count.index + 1, var.domain)}"
    )
  )}"
}

resource "aws_instance" "frontends" {
  count                       = "${var.create_chef_ha ? var.chef_frontend["count"] : 0}"
  ami                         = "${var.ami}"
  ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = "${var.instance["frontend_flavor"]}"
  associate_public_ip_address = "${var.instance["frontend_public"]}"
  subnet_id                   = "${element(var.az_subnet_ids, count.index)}"
  vpc_security_group_ids      = ["${var.https_security_group_id}", "${var.ssh_security_group_id}"]
  key_name                    = "${var.instance_keys["key_name"]}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["frontend"], count.index + 1, var.domain)}"
    )
  )}"

  root_block_device {
    delete_on_termination = "${var.instance["frontend_term"]}"
    volume_size           = "${var.instance["frontend_size"]}"
    volume_type           = "${var.instance["frontend_type"]}"
    iops                  = "${var.instance["frontend_iops"]}"
  }

  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y ntp",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_frontend["version"]}",
    ]
  }
}

resource "aws_eip" "frontends" {
  vpc      = true
  count    = "${var.create_chef_ha ? var.chef_frontend["count"] : 0}"
  instance = "${element(aws_instance.frontends.*.id, count.index)}"

  # depends_on = ["aws_internet_gateway.main"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["frontend"], count.index + 1, var.domain)}"
    )
  )}"
}

resource "aws_route53_record" "backends" {
  count   = "${var.create_chef_ha ? var.chef_backend["count"] : 0}"
  zone_id = "${var.zone_id}"
  name    = "${element(aws_instance.backends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_eip.backends.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "frontend" {
  count   = "${var.create_chef_ha ? var.chef_frontend["count"] : 0}"
  zone_id = "${var.zone_id}"
  name    = "${element(aws_instance.frontends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_eip.frontends.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "alb" {
  zone_id = "${var.zone_id}"
  name    = "${local.alb_fqdn}"
  type    = "CNAME"
  ttl     = "${var.r53_ttl}"
  records = ["${module.alb.dns_name}"]
}

resource "aws_route53_health_check" "frontend" {
  count             = "${var.create_chef_ha ? var.chef_frontend["count"] : 0}"
  fqdn              = "${element(aws_instance.frontends.*.tags.Name, count.index)}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.deployment_name} ${element(aws_instance.frontends.*.tags.Name, count.index)} Health Check"
    )
  )}"
}

resource "aws_s3_bucket" "logs" {
  count  = "${var.create_chef_ha ? 1 : 0}"
  bucket = "${var.log_bucket}"
  acl    = "private"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.deployment_name} Frontend ALB Logs"
    )
  )}"
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = "${var.create_chef_ha ? 1 : 0}"
  bucket = "${aws_s3_bucket.logs.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.log_bucket}-alb-logs",
  "Statement": [
    {
      "Sid": "AllowELBPutObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.elb_account_id}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.log_bucket}/alb/AWSLogs/${account_id}/*"
    }
  ]
}
POLICY
}

resource "aws_acm_certificate" "alb" {
  count             = "${var.create_chef_ha ? 1 : 0}"
  domain_name       = "${local.alb_fqdn}"
  validation_method = "DNS"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.deployment_name} Frontend Certificate"
    )
  )}"
}

resource "aws_route53_record" "cert_validation" {
  count   = "${var.create_chef_ha ? 1 : 0}"
  name    = "${aws_acm_certificate.alb.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.alb.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.alb.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = "${var.create_chef_ha ? 1 : 0}"
  certificate_arn         = "${aws_acm_certificate.alb.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

module "alb" {
  source              = "terraform-aws-modules/alb/aws"
  load_balancer_name  = "${replace(local.alb_fqdn,".","-")}-alb"
  security_groups     = ["${var.https_security_group_id}"]
  log_bucket_name     = "${aws_s3_bucket.logs.bucket}"
  log_location_prefix = "alb"
  subnets             = ["${az_subnet_ids}"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.deployment_name} Frontend Application Load Balancer"
    )
  )}"

  vpc_id = "${var.vpc_id}"

  https_listeners = "${list(map("certificate_arn", "${aws_acm_certificate.alb.arn}", "port", 443, "ssl_policy", "ELBSecurityPolicy-TLS-1-2-2017-01"))}"

  # https_listeners_count    = "1"
  # http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  # http_tcp_listeners_count = "0"
  # target_groups            = "${list(map("name", "foo", "backend_protocol", "HTTP", "backend_port", "80"))}"
  # target_groups_count      = "1"
}
