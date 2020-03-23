locals {
  validator_path = ".chef/test-validator.pem"
  admin_path = ".chef/admin.pem"
}

resource "null_resource" "chef_server_create_test_org" {
  count = var.create_test_org

  triggers = {
    chef_server_ids = join(",", var.chef_server_ids)
    server_ready    = join(",", var.server_ready)
  }

  connection {
    host        = element(var.chef_server_public_ip, 0)
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo chef-server-ctl user-create admin Admin User admin@example.com TestPassword -f admin.pem",
      "sudo chef-server-ctl org-create test TestOrg -f test-validator.pem -a admin",
      "sudo chef-server-ctl grant-server-admin-permissions admin",
    ]
  }
}

resource "null_resource" "get_admin_key" {
  count      = var.create_test_org
  depends_on = [null_resource.chef_server_create_test_org]

  triggers = {
    chef_server_ids = join(",", var.chef_server_ids)
    server_ready    = join(",", var.server_ready)
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${element(var.chef_server_public_ip, 0)}:admin.pem ${local.admin_path}"
  }
}

data "local_file" "chef_admin" {
  count      = var.create_test_org
  depends_on = [null_resource.get_admin_key]
  filename   = local.admin_path
}

resource "null_resource" "get_validator_key" {
  count      = var.create_test_org
  depends_on = [null_resource.chef_server_create_test_org]

  triggers = {
    chef_server_ids = join(",", var.chef_server_ids)
    server_ready    = join(",", var.server_ready)
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${element(var.chef_server_public_ip, 0)}:test-validator.pem ${local.validator_path}"
  }
}

data "local_file" "test_chef_validator" {
  count      = var.create_test_org
  depends_on = [null_resource.get_validator_key]
  filename   = local.validator_path
}

resource "aws_ssm_parameter" "test_chef_validator" {
  count     = var.create_test_org
  name      = "${var.validator_key_path}chef_validator"
  type      = "SecureString"
  overwrite = true
  value     = chomp(data.local_file.test_chef_validator[0].content)
}

data "template_file" "credentials" {
  template = file("${path.module}/templates/credentials")

  vars = {
    chef_server_url = "https://${var.chef_server_fqdn}/organizations/test"
  }
}

resource "local_file" "credentials" {
  content  = data.template_file.credentials.rendered
  filename = ".chef/credentials"
}
