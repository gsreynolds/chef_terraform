data "aws_region" "current" {}

resource "aws_instance" "chef_clients" {
  count = var.instance_count

  # depends_on = ["aws_instance.chef_server"]
  ami = var.ami

  # ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = var.instance["chef_client_flavor"]
  associate_public_ip_address = var.instance["chef_client_public"]
  subnet_id                   = element(var.az_subnet_ids, count.index)
  vpc_security_group_ids      = [var.ssh_security_group_id]
  key_name                    = var.instance_keys["key_name"]

  iam_instance_profile = var.unattended_registration_instance_profile

  tags = merge(
    var.default_tags,
    {
      "Name" = format(
        "%s%02d.%s",
        var.hostnames["chef_client"],
        count.index + 1,
        var.domain,
      )
    },
  )

  root_block_device {
    delete_on_termination = var.instance["chef_client_term"]
    volume_size           = var.instance["chef_client_size"]
    volume_type           = var.instance["chef_client_type"]
    iops                  = var.instance["chef_client_iops"]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ami_user
    private_key = file(var.instance_keys["key_file"])
  }

  # https://docs.chef.io/install_bootstrap.html#unattended-installs
  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y ntp python3 python3-pip",
      "export LC_ALL='en_US.UTF-8' && export LC_CTYPE='en_US.UTF-8' && sudo dpkg-reconfigure --frontend=noninteractive locales",
      "sudo pip3 -q install awscli --upgrade",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "sudo mkdir -p /etc/chef && sudo mkdir -p /var/lib/chef && sudo mkdir -p /var/log/chef",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef -d /tmp -v ${var.chef_client_version}",
      "aws ssm get-parameter --name ${var.chef_validator} --with-decryption --output text --query Parameter.Value --region ${data.aws_region.current.name} | sudo tee /etc/chef/validator.pem > /dev/null",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/first-boot.json"
    destination = "first-boot.json"
  }

  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "echo 'log_location STDOUT' | sudo tee /etc/chef/client.rb",
      "echo 'chef_server_url \"https://${var.chef_server_fqdn}/organizations/test\"' | sudo tee -a /etc/chef/client.rb",
      "echo 'validation_client_name \"test-validator\"' | sudo tee -a /etc/chef/client.rb",
      "echo 'validation_key \"/etc/chef/validator.pem\"' | sudo tee -a /etc/chef/client.rb",
      "echo 'node_name  \"${self.tags.Name}\"' | sudo tee -a /etc/chef/client.rb",
      "echo 'ssl_verify_mode :verify_peer' | sudo tee -a /etc/chef/client.rb",
      "sudo mv first-boot.json /etc/chef/first-boot.json",
      "sudo chef-client -j /etc/chef/first-boot.json --chef-license=accept",
    ]
  }
}

resource "aws_route53_record" "chef_clients" {
  count   = var.instance_count
  zone_id = var.zone_id
  name    = element(aws_instance.chef_clients.*.tags.Name, count.index)
  type    = "A"
  ttl     = var.r53_ttl
  records = [element(aws_instance.chef_clients.*.public_ip, count.index)]
}
