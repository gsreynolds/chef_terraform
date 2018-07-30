resource "aws_instance" "chef_server" {
  count                       = 1
  ami                         = "${var.ami}"
  ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = "${var.instance["chef_server_flavor"]}"
  associate_public_ip_address = "${var.instance["chef_server_public"]}"
  subnet_id                   = "${var.subnet}"
  vpc_security_group_ids      = ["${var.ssh_security_group_id}", "${var.https_security_group_id}"]
  key_name                    = "${var.instance_keys["key_name"]}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["chef_server"], count.index + 1, var.domain)}"
    )
  )}"

  root_block_device {
    delete_on_termination = "${var.instance["chef_server_term"]}"
    volume_size           = "${var.instance["chef_server_size"]}"
    volume_type           = "${var.instance["chef_server_type"]}"
    iops                  = "${var.instance["chef_server_iops"]}"
  }

  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y ntp",
      "sudo hostname ${self.tags.Name}",
      "sudo hostnamectl set-hostname ${self.tags.Name}",
      "echo ${self.tags.Name} | sudo tee /etc/hostname",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp",
      "sudo mkdir /etc/opscode",
      "echo 'topology \"standalone\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "echo 'api_fqdn \"${self.tags.Name}\"' | sudo tee -a /etc/opscode/chef-server.rb",
      "sudo chef-server-ctl reconfigure",
    ]
  }
}

resource "aws_eip" "chef_server" {
  vpc      = true
  count    = 1
  instance = "${element(aws_instance.chef_server.*.id, count.index)}"

  # depends_on = ["aws_internet_gateway.main"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.instance_hostname["chef_server"], count.index + 1, var.domain)}"
    )
  )}"
}

resource "aws_route53_record" "chef_server" {
  count   = 1
  zone_id = "${var.zone_id}"
  name    = "${element(aws_instance.chef_server.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_eip.chef_server.*.public_ip, count.index)}"]
}

resource "aws_route53_health_check" "chef_server" {
  count             = 1
  fqdn              = "${element(aws_instance.chef_server.*.tags.Name, count.index)}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} ${element(aws_instance.chef_server.*.tags.Name, count.index)} Health Check"
    )
  )}"
}
