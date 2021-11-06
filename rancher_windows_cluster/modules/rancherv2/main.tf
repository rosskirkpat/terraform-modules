# Configure the Rancher2 provider
# provider "rancher2" {
#   api_url    = var.rancher_api_endpoint
#   token_key  = var.rancher_api_token
#   insecure   = true
# }

# Configure the AWS Provider
# provider "aws" {
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
#   region     = var.aws_region
# }
# Helm provider
provider "helm" {
  kubernetes {
    config_path = local_file.kube_config_local_yaml.filename
  }
}

data "http" "myipv4" {
  url = "http://whatismyip.akamai.com/"
}

resource "random_password" "k3s_token" {
  length           = 30
  special          = true
  override_special = "_%@"
}

resource "random_password" "k3s_agent_token" {
  length           = 30
  special          = true
  override_special = "_%@"
}

resource "random_password" "rancher_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_integer" "cluster_name_append" {
  min = 1
  max = 99999
}

resource "random_integer" "local_cluster_name_append" {
  min = 1
  max = 99999
}

# Load in the modules
# module "aws_vpc_create" {
#   source               = "../aws_vpc_create"
#   # vpc_id               = [aws_vpc_create.aws_vpc.main_vpc.id]
#   # default_sg = [aws_vpc_create.aws_default_security_group.sg_default]
#   # subnet_ids = [aws_vpc_create.subnet_ids[*]]
#   # subnet = [aws_vpc_create.aws_subnet.c]

#   # vpc_name             = var.vpc_name
#   # owner                = var.owner
#   # rancher_cluster_name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
#   # vpc_domain_name      = var.vpc_domain_name
# }

module "ami" {
  source = "../ami"
}

resource "tls_private_key" "rancher_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_rancher_key" {
  key_name   = "terraform-rancher-local-cluster-key-pair-${random_integer.local_cluster_name_append.result}"
  public_key = tls_private_key.rancher_ssh_key.public_key_openssh
}

resource "local_file" "rancher_pem_file" {
  filename = format("%s/%s", "${path.root}/keys", "${aws_key_pair.generated_rancher_key.key_name}.pem") 
  # filename = "files\\${aws_key_pair.generated_rancher_key.key_name}.pem"
  sensitive_content = tls_private_key.rancher_ssh_key.private_key_pem
}


resource "aws_instance" "rancher_master" {
  count = var.instances.rancher_master.count
  tags = {
    Name        = "${var.prefix}-rancher-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = aws_key_pair.generated_rancher_key.key_name
  ami                         = module.ami.ubuntu-20_04
  instance_type               = var.instances.rancher_master.type
  associate_public_ip_address = "true"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.default_sg
  source_dest_check           = "false"
    user_data                   = base64encode(templatefile("${path.module}/files/user-data-rancher.yml", { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}" , k3s_agent_token = "${random_password.k3s_agent_token.result}", k3s_token = "${random_password.k3s_token.result}" } ))
  # user_data = "${base64encode(data.template_file.cloud-config.rendered, { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}" , k3s_agent_token = "${random_password.k3s_agent_token.result}", k3s_token = "${random_password.k3s_token.result}")}"

  root_block_device {
    volume_size = var.instances.rancher_master.volume_size
  }
  credit_specification {
    cpu_credits = "standard"
  }
}


resource "aws_security_group" "sg_kubeapi" {
    name = "sg_public_kubeapi-rancher-nodes"
    description = "additional AWS SG for allowing public IP kubeapi tcp/6443 traffic"
    vpc_id = var.vpc_id
    tags = {
      Owner       = var.owner
      DoNotDelete = "true"
    }

  dynamic "ingress" {
    iterator = item
    for_each = "${aws_instance.rancher_master.*.public_ip}"

    content {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["${format("%s/32", item.value)}"]
      description = "Inbound public kube-apiserver from cluster nodes"
      self        = true
    }
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
}
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  depends_on = [
    aws_instance.rancher_master
  ]
  count = length(aws_instance.rancher_master)
  security_group_id    = aws_security_group.sg_kubeapi.id
  network_interface_id = element(aws_instance.rancher_master.*.primary_network_interface_id, count.index)
}

resource "local_file" "kube_config_local_yaml" {
  filename = format("%s/%s", path.root, "kube_config_local.yaml")
  content = sshcommand_command.retrieve_config.result
  depends_on = [
    sshcommand_command.retrieve_config
  ]
}

provider "rancher2" {
  alias     = "bootstrap"
  insecure  = true
  api_url   = "https://${aws_instance.rancher_master[0].public_ip}.nip.io"
  bootstrap = true
  timeout   = "300s"
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]
  provider   = rancher2.bootstrap
  initial_password = "admin"
  password   = random_password.rancher_password.result
  telemetry  = true
}

# Provider config for admin
provider "rancher2" {
  alias     = "admin"
  api_url   = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}

resource "rancher2_setting" "server-url" {
  provider = rancher2.admin
  name     = "server-url"
  value    = rancher2_bootstrap.admin.url
}

resource "rancher2_token" "rancher-token" {
  provider    = rancher2.admin
  description = "Terraform ${var.owner} local cluster token"
}

# data "rancher2_cluster" "local" {
#   name = "local"
#   depends_on = [
#     rancher2_bootstrap.admin
#   ]
# }

# Create a new rancher2 resource using admin provider config
resource "rancher2_catalog" "rancher" {
  provider = rancher2.admin
  name     = "rancher"
  version  = "helm_v3"
  url      = "https://releases.rancher.com/server-charts/stable"
}

#
# Rancher backup
#
resource "rancher2_app_v2" "rancher-backup" {
  provider   = rancher2.admin
  cluster_id = "local"
  name       = "rancher-backup"
  namespace  = "cattle-resources-system"
  repo_name  = "rancher-charts"
  chart_name = "rancher-backup"
}

# resource "rancher2_cluster_sync" "wait_for_catalogs" {
#   cluster_id      = "local"
#   provider        = rancher2.admin
#   # wait_alerting   = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
#   # wait_monitoring = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
#   wait_catalogs   = true
# }

data "rancher2_role_template" "admin" {
  depends_on = [rancher2_catalog.rancher]
  provider   = rancher2.admin
  name       = "Cluster Owner"
}

# downstream cluster
resource "rancher2_cluster_v2" "rke2_win_cluster" {
  provider = rancher2.admin
  name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  # description = "RKE2 Windows Cluster"
  fleet_namespace = "fleet-default"
  kubernetes_version = "v1.21.6+rke2r1"
}

# Save kubeconfig file for interacting with the local and downstream clusters from your local machine

resource "local_file" "kube_config_downstream_yaml" {
  #   filename = format("%s/%s", path.root, "kube_config_downstream.yaml")
  filename = format("%s/%s", path.root, "${rancher2_cluster_v2.rke2_win_cluster.name}-kubeconfig.yaml")
  content  = rancher2_cluster_v2.rke2_win_cluster.kube_config
  depends_on = [
    helm_release.rancher_server,
    rancher2_cluster_v2.rke2_win_cluster
  ]
}