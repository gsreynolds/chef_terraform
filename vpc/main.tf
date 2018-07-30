resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc["cidr_block"]}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} VPC"
    )
  )}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Gateway"
    )
  )}"
}

resource "aws_subnet" "az_subnets" {
  count                   = "${length(keys(var.az_subnets))}"
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${element(keys(var.az_subnets), count.index)}"
  cidr_block              = "${element(values(var.az_subnets), count.index)}"
  map_public_ip_on_launch = true

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${var.deployment_name} Subnet - ${element(keys(var.az_subnets), count.index)}"
    )
  )}"
}

resource "aws_route" "default_gateway" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  gateway_id             = "${aws_internet_gateway.main.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "subnet_routes" {
  count          = "${length(keys(var.az_subnets))}"
  subnet_id      = "${element(aws_subnet.az_subnets.*.id, count.index)}"
  route_table_id = "${aws_vpc.main.main_route_table_id}"
}
