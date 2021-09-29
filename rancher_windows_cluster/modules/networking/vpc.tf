data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }  
}

# Discover VPC
data "aws_vpc" "target_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Discover subnet IDs.
data "aws_subnet_ids" "target_subnet_ids" {
  vpc_id = data.aws_vpc.target_vpc.id
  filter {
    name   = "tag:Owner"
    values = [var.owner]
  }
}

# get target subnets 
data "aws_subnet" "target_subnets" {
  count = "${length(data.aws_subnet_ids.target_subnet_ids.ids)}"
  id    = "${tolist(data.aws_subnet_ids.target_subnet_ids.ids)[count.index]}"
  filter {
    name   = "tag:Owner"
    values = [var.owner]
  }
}

# get target SGs from VPC
data "aws_security_groups" "target_sg" {
  filter {
    name   = "tag:Name"
    values = [var.sg_name]
  }
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.target_vpc.id]
  }
}

# resource "aws_vpc" "main" {
#   cidr_block           = "172.32.0.0/16"
#   enable_dns_hostnames = true
#   tags = {
#     Name = var.vpc_name
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }

# resource "aws_subnet" "a" {
#   map_public_ip_on_launch = "true"
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "172.32.16.0/20"
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   tags = {
#     Name = var.vpc_name
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }

# resource "aws_subnet" "b" {
#   map_public_ip_on_launch = "true"
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "172.32.32.0/20"
#   availability_zone       = data.aws_availability_zones.available.names[1]
#   tags = {
#     Name = var.vpc_name
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }

# resource "aws_subnet" "c" {
#   map_public_ip_on_launch = "true"
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "172.32.64.0/20"
#   availability_zone       = data.aws_availability_zones.available.names[2]
#   tags = {
#     Name = var.vpc_name
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }

# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
# }

# resource "aws_route_table" "main" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }
# }

# resource "aws_main_route_table_association" "main" {
#   vpc_id         = aws_vpc.main.id
#   route_table_id = aws_route_table.main.id
# }

# resource "aws_vpc_dhcp_options" "main" {
#   domain_name         = var.vpc_domain_name
#   domain_name_servers = ["8.8.8.8", "8.8.4.4", "10.0.0.2"]

#   tags = {
#     Name = var.vpc_name
#   }
# }

# resource "aws_vpc_dhcp_options_association" "dns_resolver" {
#   vpc_id          = aws_vpc.main.id
#   dhcp_options_id = aws_vpc_dhcp_options.main.id
# }