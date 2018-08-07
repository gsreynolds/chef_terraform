output "chef_automate_ids" {
  value = "${aws_instance.automate_server.*.id}"
}

output "chef_automate_public_ip" {
  value = "${aws_eip.automate_server.*.public_ip}"
}
