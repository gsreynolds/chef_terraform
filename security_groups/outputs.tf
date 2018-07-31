output "ssh_security_group_id" {
  value = "${aws_security_group.ssh.id}"
}

output "https_security_group_id" {
  value = "${aws_security_group.https.id}"
}

output "backend_security_group_id" {
  value = "${aws_security_group.backend.id}"
}
