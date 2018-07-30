output "chef_server_fqdn" {
  value = "${aws_instance.chef_server.tags.Name}"
}
