output "chef_alb_fqdn" {
  value = aws_route53_record.chef_alb.name
}

output "automate_alb_fqdn" {
  value = aws_route53_record.automate_alb.name
}

output "forward_to_automate_rule_id" {
  value = aws_lb_listener_rule.forward_to_automate.id
}

output "forward_to_chef_rule_id" {
  value = aws_lb_listener_rule.forward_to_chef.id
}
