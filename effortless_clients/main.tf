resource "aws_instance" "effortless_clients" {
  count = "${var.instance_count}"

  ami = "${var.ami}"

  # ebs_optimized               = "${var.instance["ebs_optimized"]}"
  instance_type               = "${var.instance["effortless_client_flavor"]}"
  associate_public_ip_address = "${var.instance["effortless_client_public"]}"
  subnet_id                   = "${element(var.az_subnet_ids, count.index)}"
  vpc_security_group_ids      = ["${var.ssh_security_group_id}"]
  key_name                    = "${var.instance_keys["key_name"]}"


  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("%s%02d.%s", var.hostnames["effortless_client"], count.index + 1, var.domain)}"
    )
  )}"

  root_block_device {
    delete_on_termination = "${var.instance["effortless_client_term"]}"
    volume_size           = "${var.instance["effortless_client_size"]}"
    volume_type           = "${var.instance["effortless_client_type"]}"
    iops                  = "${var.instance["effortless_client_iops"]}"
  }

  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }

  # https://docs.chef.io/install_bootstrap.html#unattended-installs
  provisioner "remote-exec" {
    inline = [
      "set -Eeu",
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt update && sudo apt upgrade -y && sudo apt install -y ntp python3 python3-pip",
    ]
  }

  provisioner "habitat" {
    use_sudo = true
    service_type = "systemd"

    service {
      name = "${var.origin}/${var.effortless_audit}"
      # user_toml = "${file("conf/redis.toml")}"
    }

    service {
      name = "${var.origin}/${var.effortless_config}"
      # user_toml = "${file("conf/redis.toml")}"
    }
  }
}

resource "aws_route53_record" "effortless_clients" {
  count   = "${var.instance_count}"
  zone_id = "${var.zone_id}"
  name    = "${element(aws_instance.effortless_clients.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_instance.effortless_clients.*.public_ip, count.index)}"]
}