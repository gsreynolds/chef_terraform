output "test_chef_validator" {
  value = aws_ssm_parameter.test_chef_validator[0].name
}

output "chef_admin" {
  value = data.local_file.chef_admin[0].content
}
