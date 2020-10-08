# Instances

resource "aws_instance" "backends" {
  count                       = var.create_chef_ha ? var.chef_backend["count"] : 0
  ami                         = var.ami
  ebs_optimized               = var.instance["ebs_optimized"]
  instance_type               = var.instance["backend_flavor"]
  associate_public_ip_address = var.instance["backend_public"]
  subnet_id                   = element(var.az_subnet_ids, count.index)
  vpc_security_group_ids      = [var.backend_security_group_id, var.ssh_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["backend"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["backend_term"]
    volume_size           = var.instance["backend_size"]
    volume_type           = var.instance["backend_type"]
    iops                  = var.instance["backend_iops"]
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
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y ntp",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-backend -d /tmp -v ${var.chef_backend["version"]}",
      "echo 'publish_address \"${self.private_ip}\"'|sudo tee -a /etc/chef-backend/chef-backend.rb",
      "echo 'postgresql.md5_auth_cidr_addresses = [\"samehost\",\"samenet\",\"${var.vpc["cidr_block"]}\"]'|sudo tee -a /etc/chef-backend/chef-backend.rb",
    ]
  }
}

resource "aws_eip" "backends" {
  vpc      = true
  count    = var.create_chef_ha ? var.chef_backend["count"] : 0
  instance = element(aws_instance.backends.*.id, count.index)

  # depends_on = ["aws_internet_gateway.main"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["backend"],
        count.index + 1,
        var.domain,
      )
    },
  )
}

resource "aws_instance" "frontends" {
  count                       = var.create_chef_ha ? var.chef_frontend["count"] : 0
  ami                         = var.ami
  ebs_optimized               = var.instance["ebs_optimized"]
  instance_type               = var.instance["frontend_flavor"]
  associate_public_ip_address = var.instance["frontend_public"]
  subnet_id                   = element(var.az_subnet_ids, count.index)
  vpc_security_group_ids      = [var.https_security_group_id, var.ssh_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["frontend"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["frontend_term"]
    volume_size           = var.instance["frontend_size"]
    volume_type           = var.instance["frontend_type"]
    iops                  = var.instance["frontend_iops"]
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
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y ntp",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_frontend["version"]}",
    ]
  }
}

resource "aws_eip" "frontends" {
  vpc      = true
  count    = var.create_chef_ha ? var.chef_frontend["count"] : 0
  instance = element(aws_instance.frontends.*.id, count.index)

  # depends_on = ["aws_internet_gateway.main"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["frontend"],
        count.index + 1,
        var.domain,
      )
    },
  )
}

resource "aws_route53_record" "backends" {
  count   = var.create_chef_ha ? var.chef_backend["count"] : 0
  zone_id = var.zone_id
  name    = element(aws_instance.backends.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_eip.backends.*.public_ip, count.index)]
}

resource "aws_route53_record" "frontend" {
  count   = var.create_chef_ha ? var.chef_frontend["count"] : 0
  zone_id = var.zone_id
  name    = element(aws_instance.frontends.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_eip.frontends.*.public_ip, count.index)]
}

resource "aws_route53_health_check" "frontend" {
  count             = var.create_chef_ha ? var.chef_frontend["count"] : 0
  fqdn              = element(aws_instance.frontends.*.tags.Name, count.index)
  port              = 443
  type              = "HTTPS"
  resource_path     = "/_status"
  failure_threshold = "5"
  request_interval  = "30"

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} ${element(aws_instance.frontends.*.tags.Name, count.index)} Health Check"
    },
  )
}

resource "null_resource" "create_cluster_leader" {
  count      = var.create_chef_ha ? 1 : 0
  depends_on = [aws_eip.backends]

  connection {
    host        = aws_eip.backends[0].public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo chef-backend-ctl create-cluster --accept-license --quiet -y",
      "sudo cp /etc/chef-backend/chef-backend-secrets.json chef-backend-secrets.json",
      "sudo chown ${var.ami_user}:${var.ami_user} chef-backend-secrets.json",
    ]
  }

  # Copy back file
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/.chef && scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${aws_eip.backends[0].public_ip}:chef-backend-secrets.json ${path.module}/.chef/"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo rm chef-backend-secrets.json",
    ]
  }
}

resource "null_resource" "followers_join_cluster" {
  count      = var.create_chef_ha ? var.chef_backend["count"] - 1 : 0
  depends_on = [null_resource.create_cluster_leader]

  connection {
    host        = element(aws_eip.backends.*.public_ip, count.index + 1)
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "file" {
    source      = "${path.module}/.chef/chef-backend-secrets.json"
    destination = "chef-backend-secrets.json"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sleep ${120 * count.index + 1}",
      "sudo mkdir -p /etc/chef-backend",
      "echo \"publish_address '${element(aws_eip.backends.*.private_ip, count.index + 1)}'\" | sudo tee /etc/chef-backend/chef-backend.rb",
      "sudo chef-backend-ctl join-cluster ${aws_eip.backends[0].private_ip} --accept-license -s chef-backend-secrets.json -y --quiet",
      "sudo rm chef-backend-secrets.json",
    ]
  }
}

resource "null_resource" "chef_server_gen_frontend_config" {
  count      = var.create_chef_ha ? var.chef_frontend["count"] : 0
  depends_on = [null_resource.followers_join_cluster]

  connection {
    host        = aws_eip.backends[0].public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo chef-backend-ctl gen-server-config ${element(aws_instance.frontends.*.tags.Name, count.index)} > chef-server.rb-${element(aws_instance.frontends.*.tags.Name, count.index)}",
    ]
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${aws_eip.backends[0].public_ip}:chef-server.rb-${element(aws_instance.frontends.*.tags.Name, count.index)} ${path.module}/.chef/"
  }
}

resource "null_resource" "chef_server_upload_frontend_config" {
  count      = var.create_chef_ha ? var.chef_frontend["count"] : 0
  depends_on = [null_resource.chef_server_gen_frontend_config]

  connection {
    host        = element(aws_eip.frontends.*.public_ip, count.index)
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "file" {
    source      = "${path.module}/.chef/chef-server.rb-${element(aws_instance.frontends.*.tags.Name, count.index)}"
    destination = "chef-server.rb"
  }
}

resource "null_resource" "configure_first_frontend" {
  count      = var.create_chef_ha ? 1 : 0
  depends_on = [null_resource.chef_server_upload_frontend_config]

  connection {
    host        = aws_eip.frontends[0].public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo cp chef-server.rb /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
      "sudo cp /etc/opscode/private-chef-secrets.json /var/opt/opscode/upgrades/migration-level ~",
      "sudo chown ${var.ami_user}:${var.ami_user} *",
    ]
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${aws_eip.frontends[0].public_ip}:private-chef-secrets.json ${path.module}/.chef/"
  }

  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user}@${aws_eip.frontends[0].public_ip}:migration-level ${path.module}/.chef/"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo rm chef-server.rb private-chef-secrets.json",
    ]
  }
}

resource "null_resource" "configure_other_frontends" {
  count      = var.create_chef_ha ? var.chef_frontend["count"] - 1 : 0
  depends_on = [null_resource.configure_first_frontend]

  connection {
    host        = element(aws_eip.frontends.*.public_ip, count.index + 1)
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "file" {
    source      = "${path.module}/.chef/private-chef-secrets.json"
    destination = "private-chef-secrets.json"
  }

  provisioner "file" {
    source      = "${path.module}/.chef/migration-level"
    destination = "migration-level"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo cp chef-server.rb /etc/opscode/chef-server.rb",
      "sudo cp private-chef-secrets.json /etc/opscode/private-chef-secrets.json",
      "sudo mkdir -p /var/opt/opscode/upgrades",
      "sudo cp migration-level /var/opt/opscode/upgrades/migration-level",
      "sudo touch /var/opt/opscode/bootstrapped",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
      "sudo rm chef-server.rb private-chef-secrets.json migration-level",
    ]
  }
}

resource "null_resource" "configure_data_collection" {
  count      = var.create_chef_ha ? var.chef_frontend["count"] : 0
  depends_on = [null_resource.configure_other_frontends]

  connection {
    host        = element(aws_eip.frontends.*.public_ip, count.index)
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo chef-server-ctl set-secret data_collector token '${var.data_collector_token}'",
      "sudo chef-server-ctl restart nginx && sudo chef-server-ctl restart opscode-erchef",
      "echo 'data_collector[\"root_url\"] =  \"https://${var.automate_fqdn}/data-collector/v0/\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'data_collector[\"proxy\"] = true' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'profiles[\"root_url\"] = \"https://${var.automate_fqdn}\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'opscode_erchef[\"max_request_size\"] = 2000000' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'insecure_addon_compat false' | sudo tee -a /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure",
    ]
  }
}
