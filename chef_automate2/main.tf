resource "aws_instance" "automate_server" {
  count                       = 1
  ami                         = var.ami
  ebs_optimized               = var.instance["ebs_optimized"]
  instance_type               = var.instance["automate_server_flavor"]
  associate_public_ip_address = var.instance["automate_server_public"]
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.ssh_security_group_id, var.https_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["automate_server"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["automate_server_term"]
    volume_size           = var.instance["automate_server_size"]
    volume_type           = var.instance["automate_server_type"]
    iops                  = var.instance["automate_server_iops"]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "file" {
    source      = "${path.module}/iam/"
    destination = "/home/${var.ami_user}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y ntp unzip",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "wget https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip",
      "sudo unzip chef-automate_linux_amd64.zip -d /usr/local/bin",
      "echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf",
      "echo vm.dirty_expire_centisecs=20000 | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p /etc/sysctl.conf",
      "sudo chef-automate init-config --fqdn ${var.automate_fqdn}",
      "sudo chef-automate deploy --channel current --upgrade-strategy none --accept-terms-and-mlsa config.toml",
      "sudo chef-automate license apply \"${var.automate_license}\"",
      "sudo chown ${var.ami_user}:${var.ami_user} automate-credentials.toml",
      "export TOKEN=$(sudo chef-automate iam token create admin --admin)",
      "echo admin-token = \"$TOKEN\" >> automate-credentials.toml",
      "echo ingest-token = \"$(sudo chef-automate iam token create ingest)\" >> automate-credentials.toml",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d '{\"members\":[\"token:ingest\"]}' https://localhost/apis/iam/v2/policies/ingest-access/members:add",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d @administrator-access-members.json -X PUT https://localhost/apis/iam/v2/policies/administrator-access/members",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d '{\"id\": \"development\", \"name\": \"Development\"}' https://localhost/apis/iam/v2/projects",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d '{\"id\": \"test\", \"name\": \"Test\"}' https://localhost/apis/iam/v2/projects",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d '{\"id\": \"production\", \"name\": \"Production\"}' https://localhost/apis/iam/v2/projects",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d @project-development-rule.json https://localhost/apis/iam/v2/projects/development/rules",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d @project-test-rule.json https://localhost/apis/iam/v2/projects/test/rules",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" -d @project-production-rule.json https://localhost/apis/iam/v2/projects/production/rules",
      "curl -sk -H \"api-token: $TOKEN\" https://localhost/apis/iam/v2/apply-rules -X POST",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/development-project-owners/members -d @project-development-members-owners.json -X PUT",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/development-project-viewers/members -d @project-development-members-viewers.json -X PUT",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/test-project-owners/members -d @project-test-members-owners.json -X PUT",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/test-project-viewers/members -d @project-test-members-viewers.json -X PUT",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/production-project-owners/members -d @project-production-members-owners.json -X PUT",
      "curl -sk -H \"api-token: $TOKEN\" -H \"Content-Type: application/json\" https://localhost/apis/iam/v2/policies/production-project-viewers/members -d @project-production-members-viewers.json -X PUT"
    ]
  }
}

resource "aws_eip" "automate_server" {
  vpc      = true
  count    = 1
  instance = element(aws_instance.automate_server.*.id, count.index)

  # depends_on = ["aws_internet_gateway.main"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["automate_server"],
        count.index + 1,
        var.domain,
      )
    },
  )
}

data "external" "a2_secrets" {
  program    = ["bash", "${path.module}/get-automate-secrets.sh"]
  depends_on = [aws_eip.automate_server]
  query = {
    ssh_user = var.ami_user
    ssh_key  = var.instance_keys["key_file"]
    a2_ip    = aws_eip.automate_server[0].public_ip
  }
}

resource "aws_route53_record" "automate_server" {
  count   = 1
  zone_id = var.zone_id
  name    = element(aws_instance.automate_server.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_eip.automate_server.*.public_ip, count.index)]
}

resource "aws_route53_health_check" "automate_server" {
  count             = 1
  fqdn              = element(aws_instance.automate_server.*.tags.Name, count.index)
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} ${element(aws_instance.automate_server.*.tags.Name, count.index)} Health Check"
    },
  )
}
