resource "aws_instance" "chef_server" {
  count                       = var.create_chef_server ? 1 : 0
  ami                         = var.ami
  ebs_optimized               = var.instance["ebs_optimized"]
  instance_type               = var.instance["chef_server_flavor"]
  associate_public_ip_address = var.instance["chef_server_public"]
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.ssh_security_group_id, var.https_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["chef_server"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["chef_server_term"]
    volume_size           = var.instance["chef_server_size"]
    volume_type           = var.instance["chef_server_type"]
    iops                  = var.instance["chef_server_iops"]
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
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_server_version}",
      "sudo mkdir -p /etc/opscode",
      "echo 'topology \"standalone\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'api_fqdn \"${self.tags.Name}\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
    ]
  }
}

resource "aws_eip" "chef_server" {
  vpc      = true
  count    = var.create_chef_server ? 1 : 0
  instance = element(aws_instance.chef_server.*.id, count.index)

  # depends_on = ["aws_internet_gateway.main"]

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["chef_server"],
        count.index + 1,
        var.domain,
      )
    },
  )
}

resource "aws_route53_record" "chef_server" {
  count   = var.create_chef_server ? 1 : 0
  zone_id = var.zone_id
  name    = element(aws_instance.chef_server.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_eip.chef_server.*.public_ip, count.index)]
}

resource "aws_route53_health_check" "chef_server" {
  count             = var.create_chef_server ? 1 : 0
  fqdn              = element(aws_instance.chef_server.*.tags.Name, count.index)
  port              = 443
  type              = "HTTPS"
  resource_path     = "/_status"
  failure_threshold = "5"
  request_interval  = "30"

  tags = merge(
    var.default_tags,
    {
      "Name" = "${var.deployment_name} ${element(aws_instance.chef_server.*.tags.Name, count.index)} Health Check"
    },
  )
}

resource "null_resource" "configure_data_collection" {
  count      = var.create_chef_server ? 1 : 0
  depends_on = [aws_eip.chef_server]

  connection {
    host        = element(aws_eip.chef_server.*.public_ip, count.index)
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
