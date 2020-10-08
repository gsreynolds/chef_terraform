output "chef_automate_ids" {
  value = aws_instance.automate_server.*.id
}

output "chef_automate_public_ip" {
  value = aws_eip.automate_server.*.public_ip
}

output "a2_admin" {
  value = data.external.a2_secrets.result["a2_admin"]
}

output "a2_admin_password" {
  value = data.external.a2_secrets.result["a2_password"]
}

output "data_collector_token" {
  value = data.external.a2_secrets.result["a2_ingest_token"]
}

output "admin_token" {
  value = data.external.a2_secrets.result["a2_admin_token"]
}

output "a2_url" {
  value = data.external.a2_secrets.result["a2_url"]
}
