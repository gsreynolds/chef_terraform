output "chef_alb_fqdn" {
  value = "${module.chef_alb.chef_alb_fqdn}"
}

output "automate_alb_fqdn" {
  value = "${module.chef_alb.automate_alb_fqdn}"
}

output "a2_admin" {
  value = "${module.chef_automate2.a2_admin}"
}

output "a2_admin_password" {
  value = "${module.chef_automate2.a2_admin_password}"
}

output "data_collector_token" {
  value = "${module.chef_automate2.data_collector_token}"
}

output "a2_url" {
  value = "${module.chef_automate2.a2_url}"
}
