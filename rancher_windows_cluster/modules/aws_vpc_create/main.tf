  # for_each       = aws_subnet[*].id
  # subnet_id      = [each.value]

data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "myipv4" {
  url = "http://whatismyip.akamai.com/"
}

resource "aws_vpc" "main_vpc" {
    cidr_block           = "172.32.0.0/16"
    enable_dns_hostnames = true
    tags = {
      Name        = var.vpc_name
      Owner       = var.owner
      DoNotDelete = "true"
      "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
    }
}

resource "aws_subnet" "a" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.32.16.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Owner       = var.owner
    Name = "${var.vpc_name}-subnet-a"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
    }
}

resource "aws_subnet" "b" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.32.32.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Owner       = var.owner
    Name = "${var.vpc_name}-subnet-b"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
    }
}

resource "aws_subnet" "c" {
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "172.32.64.0/20"
  availability_zone       = data.aws_availability_zones.available.names[2]
  tags = {
    Owner       = var.owner
    Name = "${var.vpc_name}-subnet-b"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
  }
}

resource "aws_internet_gateway" "main_ig" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Owner       = var.owner
    Name = "${var.vpc_name}-ig"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_ig.id
  }
}

resource "aws_main_route_table_association" "main_rta" {
  vpc_id         = aws_vpc.main_vpc.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_vpc_dhcp_options" "main_dhcp" {
  depends_on = [
    var.vpc_domain_name
  ]
  domain_name         = var.vpc_domain_name
  domain_name_servers = ["8.8.8.8", "8.8.4.4", "10.0.0.2"]

  tags = {
    Name = "${var.vpc_name}-dhcp"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.main_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.main_dhcp.id
}

resource "aws_security_group" "sg_all" {
  name   = "${var.owner}_sg_all"
  vpc_id = aws_vpc.main_vpc.id
  description = "Swiss cheese security group for Rancher VPC"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Owner       = var.owner
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
  }
}

resource "aws_default_security_group" "sg_default" {
  vpc_id = aws_vpc.main_vpc.id

  # ingress = [ 
    ingress {
      description = "Inbound HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      # security_groups = [aws_default_security_group.sg_default.id]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
    }
    ingress {
      description = "Inbound HTTPS from ALB"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      # security_groups = [aws_default_security_group.sg_default.id]
    }
    ingress {
      description = "Inbound etcd from cluster nodes"
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      # security_groups = [aws_default_security_group.sg_default.id]
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound kube-apiserver from cluster nodes"
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      # security_groups = ""
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound Canal/Flannel VXLAN from cluster nodes"
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      # security_groups = ""
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound Canal/Flannel VXLAN from cluster nodes"
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound Typha for Calico Felix from cluster nodes"
      from_port   = 5473
      to_port     = 5473
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound kubelet for Canal/Flannel VXLAN from cluster nodes"
      from_port   = 10250
      to_port     = 10252
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound RKE2 Proxy from cluster nodes"
      from_port   = 9345
      to_port     = 9345
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound k8s node ports"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound k8s node ports"
      from_port   = 30000
      to_port     = 32767
      protocol    = "udp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound port for BGP"
      from_port   = 179
      to_port     = 179
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
    ingress {
      description = "Inbound RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = ["${chomp(data.http.myipv4.body)}/32"]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
    }
    ingress {
      description = "Inbound ssh"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${chomp(data.http.myipv4.body)}/32"]
      # ipv6_cidr_blocks = ["${chomp(data.http.myipv6.body)}"]
    }
    ingress {
      description = "Prometheus metrics"
      from_port   = 9796
      to_port     = 9796
      protocol    = "tcp"
      cidr_blocks = [aws_vpc.main_vpc.cidr_block]
      # ipv6_cidr_blocks = [aws_vpc.main_vpc.ipv6_cidr_block]
      self        = true
    }
  # egress = [
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  tags = {
    Owner       = var.owner
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "shared"
  }
}
