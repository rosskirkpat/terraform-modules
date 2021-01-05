data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "172.32.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "a" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.32.16.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "b" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.32.32.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "c" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.32.64.0/20"
  availability_zone       = data.aws_availability_zones.available.names[2]
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name         = var.vpc_domain_name
  domain_name_servers = ["8.8.8.8", "8.8.4.4", "10.0.0.2"]

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}