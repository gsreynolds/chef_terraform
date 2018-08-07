locals {
  data_collector_token_path = "${path.module}/.chef/data-collector.token"
  validator_path            = "${path.module}/.chef/test-validator.pem"
}

resource "null_resource" "chef_server_standalone_config" {
  triggers {
    chef_server_ids = "${join(",", var.chef_server_ids)}"
  }

  connection {
    host        = "${var.chef_server_public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/.chef && scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${var.automate_server_public_ip}:data-collector.token ${local.data_collector_token_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl set-secret data_collector token '${chomp(file("${local.data_collector_token_path}"))}'",
      "sudo chef-server-ctl restart nginx && sudo chef-server-ctl restart opscode-erchef",
      "echo 'data_collector[\"root_url\"] =  \"https://${var.automate_fqdn}/data-collector/v0/\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'data_collector[\"proxy\"] = true' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'profiles[\"root_url\"] = \"https://${var.automate_fqdn}\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl org-create test TestOrg -f test-validator.pem",
      "sudo chef-server-ctl user-create admin Admin User admin@example.com TestPassword -o test -f admin.pem",
      "sudo chef-server-ctl grant-server-admin-permissions admin",
    ]
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${var.chef_server_public_ip}:test-validator.pem ${local.validator_path}"
  }
}

resource "aws_ssm_parameter" "test_chef_validator" {
  name      = "${var.validator_key_path}chef_validator"
  type      = "SecureString"
  overwrite = true
  value     = "${chomp(file("${local.validator_path}"))}"
}
