locals {
  chef_alb_fqdn     = "${var.hostnames["chef_server"]}.${var.domain}"
  automate_alb_fqdn = "${var.hostnames["automate_server"]}.${var.domain}"
}

# resource "aws_s3_bucket" "alb_logs" {
#   bucket = var.log_bucket
#   acl    = "private"

#   tags = merge(
#     var.default_tags,
#     {
#       "Name" = "${var.deployment_name} Frontend ALB Logs"
#     },
#   )
# }

# resource "aws_s3_bucket_policy" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Id": "${var.log_bucket}-alb-logs",
#   "Statement": [
#     {
#       "Sid": "AllowELBPutObject",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::${var.elb_account_id}:root"
#       },
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::${var.log_bucket}/alb/AWSLogs/${var.account_id}/*"
#     }
#   ]
# }
# POLICY
# }

resource "aws_acm_certificate" "alb" {
  domain_name               = local.chef_alb_fqdn
  subject_alternative_names = [local.automate_alb_fqdn]

  validation_method = "DNS"

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} Frontend Certificate"
    },
  )
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "alb_cert" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}


resource "aws_route53_record" "chef_alb" {
  zone_id = var.zone_id
  name    = local.chef_alb_fqdn
  type    = "CNAME"
  ttl     = var.r53_ttl
  records = [module.alb.this_lb_dns_name]
}

resource "aws_route53_record" "automate_alb" {
  zone_id = var.zone_id
  name    = local.automate_alb_fqdn
  type    = "CNAME"
  ttl     = var.r53_ttl
  records = [module.alb.this_lb_dns_name]
}

module "alb" {
  source          = "terraform-aws-modules/alb/aws"
  name            = "${replace(local.chef_alb_fqdn, ".", "-")}-alb"
  security_groups = [var.https_security_group_id]
  # access_logs = {
  #   bucket = aws_s3_bucket.alb_logs.bucket
  # }
  subnets = var.subnets

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} Frontend Application Load Balancer"
    },
  )

  vpc_id = var.vpc_id

  https_listeners = [
    {
      "certificate_arn" = aws_acm_certificate.alb.arn
      "port"            = 443
      "ssl_policy"      = "ELBSecurityPolicy-TLS-1-2-2017-01"
    },
  ]

  target_groups = [
    {
      "name"             = "automate-https"
      "backend_protocol" = "HTTPS"
      "backend_port"     = "443"
    },
    {
      "name"             = "chef-https"
      "backend_protocol" = "HTTPS"
      "backend_port"     = "443"
    },
  ]
}

resource "aws_lb_target_group_attachment" "automate-https" {
  count            = "1"
  target_group_arn = element(module.alb.target_group_arns, 0)
  target_id        = element(var.automate_target_ids, count.index)
  port             = 443
}

resource "aws_lb_target_group_attachment" "chef-https" {
  count            = var.chef_target_count
  target_group_arn = element(module.alb.target_group_arns, 1)
  target_id        = element(var.chef_target_ids, count.index)
  port             = 443
}

resource "aws_lb_listener_rule" "forward_to_automate" {
  listener_arn = element(module.alb.https_listener_arns, 0)

  action {
    type             = "forward"
    target_group_arn = element(module.alb.target_group_arns, 0)
  }

  condition {
    host_header {
      values = [local.automate_alb_fqdn]
    }
  }
}

resource "aws_lb_listener_rule" "forward_to_chef" {
  listener_arn = element(module.alb.https_listener_arns, 0)

  action {
    type             = "forward"
    target_group_arn = element(module.alb.target_group_arns, 1)
  }

  condition {
    host_header {
      values = [local.chef_alb_fqdn]
    }
  }
}
