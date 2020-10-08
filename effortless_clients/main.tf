data "template_file" "install-hab" {
  template = file("${path.module}/templates/install-hab.sh.tpl")
  # vars = {
  #   ssh_user = "${var.ami_user}"
  # }
}

data "template_file" "hab-sup" {
  template = file("${path.module}/templates/hab-sup.service.tpl")

  vars = {
    flags = ""
  }
}

data "template_file" "audit-user-toml" {
  template = file("${path.module}/templates/audit-user.toml.tpl")

  vars = {
    automate_fqdn        = var.automate_fqdn
    data_collector_token = var.data_collector_token
  }
}

data "template_file" "config-user-toml" {
  template = file("${path.module}/templates/config-user.toml.tpl")

  vars = {
    automate_fqdn        = var.automate_fqdn
    data_collector_token = var.data_collector_token
  }
}

resource "aws_instance" "effortless_clients" {
  count = var.instance_count

  ami = var.ami

  # ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = var.instance["effortless_client_flavor"]
  associate_public_ip_address = var.instance["effortless_client_public"]
  subnet_id                   = element(var.az_subnet_ids, count.index)
  vpc_security_group_ids      = [var.ssh_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["effortless_client"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["effortless_client_term"]
    volume_size           = var.instance["effortless_client_size"]
    volume_type           = var.instance["effortless_client_type"]
    iops                  = var.instance["effortless_client_iops"]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y ntp python3 python3-pip",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
    ]
  }

  # provisioner "habitat" {
  #   use_sudo     = true
  #   service_type = "systemd"

  #   service {
  #     name      = "${var.origin}/${var.effortless_audit}"
  #     user_toml = "${data.template_file.audit-user-toml.rendered}"
  #   }

  #   service {
  #     name      = "${var.origin}/${var.effortless_config}"
  #     user_toml = "${data.template_file.config-user-toml.rendered}"
  #   }
  # }

  provisioner "file" {
    content     = data.template_file.hab-sup.rendered
    destination = "hab-sup.service"
  }

  provisioner "file" {
    content     = data.template_file.install-hab.rendered
    destination = "install-hab.sh"
  }

  provisioner "file" {
    content     = data.template_file.audit-user-toml.rendered
    destination = "audit-user.toml"
  }

  provisioner "file" {
    content     = data.template_file.config-user-toml.rendered
    destination = "config-user.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "chmod +x install-hab.sh",
      "sudo ./install-hab.sh",
      "sudo mkdir -p /hab/user/${var.effortless_audit}/config /hab/user/${var.effortless_config}/config",
      "sudo mv audit-user.toml /hab/user/${var.effortless_audit}/config/user.toml",
      "sudo mv config-user.toml /hab/user/${var.effortless_config}/config/user.toml",
      "sudo chown -R hab:hab /hab/user",
      "sleep 30",
      "sudo hab svc load ${var.origin}/${var.effortless_audit} --strategy at-once",
      "sudo hab svc load ${var.origin}/${var.effortless_config} --strategy at-once",
    ]
  }
}

resource "aws_route53_record" "effortless_clients" {
  count   = var.instance_count
  zone_id = var.zone_id
  name    = element(aws_instance.effortless_clients.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_instance.effortless_clients.*.public_ip, count.index)]
}
