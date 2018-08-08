output "chef_automate_ids" {
  value = "${aws_instance.automate_server.*.id}"
}

output "chef_automate_public_ip" {
  value = "${aws_eip.automate_server.*.public_ip}"
}

output "data_collector_token" {
  value = "${chomp("${data.local_file.data_collector_token.content}")}"
}
