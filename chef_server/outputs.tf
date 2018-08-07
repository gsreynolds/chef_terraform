# must use splat syntax to access aws_instance.chef_server attribute "id", because it has "count" set
output "chef_server_id" {
  value = "${aws_instance.chef_server.*.id}"
}

output "chef_server_public_ip" {
  value = "${aws_eip.chef_server.*.public_ip}"
}
