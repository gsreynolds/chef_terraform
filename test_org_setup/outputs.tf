output "test_chef_validator" {
  value = "${aws_ssm_parameter.test_chef_validator.name}"
}
