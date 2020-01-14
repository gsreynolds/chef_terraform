output "frontend_ids" {
  value = aws_instance.frontends.*.id
}

output "chef_server_public_ip" {
  value = aws_eip.frontends.*.public_ip
}

output "data_collector_configured" {
  value = tolist(null_resource.configure_data_collection.*.id)
}
