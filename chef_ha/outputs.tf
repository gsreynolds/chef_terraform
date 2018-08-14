output "frontend_ids" {
  value = "${aws_instance.frontends.*.id}"
}

output "chef_server_public_ip" {
  value = "${aws_eip.frontends.*.public_ip}"
}
