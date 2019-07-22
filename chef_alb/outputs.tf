output "chef_alb_fqdn" {
  value = aws_route53_record.chef_alb.name
}

output "automate_alb_fqdn" {
  value = aws_route53_record.automate_alb.name
}
