locals {
  validator_path = "${path.module}/.chef/test-validator.pem"
}

resource "null_resource" "chef_server_create_test_org" {
  triggers {
    chef_server_ids = "${join(",", var.chef_server_ids)}"
    server_ready    = "${join(",", var.server_ready)}"
  }

  connection {
    host        = "${var.chef_server_public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo chef-server-ctl org-create test TestOrg -f test-validator.pem",
      "sudo chef-server-ctl user-create admin Admin User admin@example.com TestPassword -o test -f admin.pem",
      "sudo chef-server-ctl grant-server-admin-permissions admin",
    ]
  }

  # FIXME: scp admin.pem
}

resource "null_resource" "get_validator_key" {
  depends_on = ["null_resource.chef_server_create_test_org"]

  triggers {
    chef_server_ids = "${join(",", var.chef_server_ids)}"
    server_ready    = "${join(",", var.server_ready)}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/.chef && scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${var.chef_server_public_ip}:test-validator.pem ${local.validator_path}"
  }
}

data "local_file" "test_chef_validator" {
  depends_on = ["null_resource.get_validator_key"]
  filename   = "${local.validator_path}"
}

resource "aws_ssm_parameter" "test_chef_validator" {
  name      = "${var.validator_key_path}chef_validator"
  type      = "SecureString"
  overwrite = true
  value     = "${chomp("${data.local_file.test_chef_validator.content}")}"
}
