# must use splat syntax to access aws_instance.chef_server attribute "id", because it has "count" set
output "chef_server_id" {
  value = "${aws_instance.chef_server.*.id}"
}
