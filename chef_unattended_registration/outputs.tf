output "instance_profile" {
  value = aws_iam_instance_profile.chef_validator[0].id
}
