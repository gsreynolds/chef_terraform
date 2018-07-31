output "frontend_ids" {
  value = "${aws_instance.frontends.*.id}"
}
