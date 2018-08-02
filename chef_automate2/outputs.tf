output "chef_automate_ids" {
  value = "${aws_instance.automate_server.*.id}"
}
