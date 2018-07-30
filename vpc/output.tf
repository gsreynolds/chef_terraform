output "subnet_ids" {
  description = "List of IDs of private subnets"
  value       = ["${aws_subnet.az_subnets.*.id}"]
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}
