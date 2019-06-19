output "chef_alb_fqdn" {
  value = "${module.chef_alb.chef_alb_fqdn}"
}

output "automate_alb_fqdn" {
  value = "${module.chef_alb.automate_alb_fqdn}"
}
