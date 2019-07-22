output "ssh_security_group_id" {
  value = module.ssh_sg.this_security_group_id
}

output "https_security_group_id" {
  value = module.https_all_sg.this_security_group_id
}

output "backend_security_group_id" {
  value = module.backend_sg.this_security_group_id
}
