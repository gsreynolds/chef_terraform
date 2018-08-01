locals {
  alb_fqdn = "${var.frontend_hostname}.${var.domain}"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.log_bucket}"
  acl    = "private"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Frontend ALB Logs"
    )
  )}"
}

resource "aws_s3_bucket_policy" "alb_logs" {
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
      "Resource": "arn:aws:s3:::${var.log_bucket}/alb/AWSLogs/${var.account_id}/*"
    }
  ]
}
POLICY
}

resource "aws_acm_certificate" "alb" {
  domain_name       = "${local.alb_fqdn}"
  validation_method = "DNS"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Frontend Certificate"
    )
  )}"
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.alb.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.alb.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.alb.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.alb.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

resource "aws_route53_record" "alb" {
  zone_id = "${var.zone_id}"
  name    = "${local.alb_fqdn}"
  type    = "CNAME"
  ttl     = "${var.r53_ttl}"
  records = ["${module.alb.dns_name}"]
}

module "alb" {
  source              = "terraform-aws-modules/alb/aws"
  load_balancer_name  = "${replace(local.alb_fqdn,".","-")}-alb"
  security_groups     = ["${var.https_security_group_id}"]
  log_bucket_name     = "${aws_s3_bucket.logs.bucket}"
  log_location_prefix = "alb"
  subnets             = ["${var.subnets}"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Frontend Application Load Balancer"
    )
  )}"

  vpc_id = "${var.vpc_id}"

  https_listeners       = "${list(map("certificate_arn", "${aws_acm_certificate.alb.arn}", "port", 443, "ssl_policy", "ELBSecurityPolicy-TLS-1-2-2017-01"))}"
  https_listeners_count = "1"
  target_groups         = "${list(map("name", "chef-https", "backend_protocol", "HTTPS", "backend_port", "443"))}"
  target_groups_count   = "1"
}

resource "aws_lb_target_group_attachment" "chef-https" {
  count            = "${var.chef_target_count}"
  target_group_arn = "${element(module.alb.target_group_arns, 0)}"
  target_id        = "${element(var.target_ids, count.index)}"
  port             = 443
}
