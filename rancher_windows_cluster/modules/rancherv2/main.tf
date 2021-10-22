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
  filename = "files\\${aws_key_pair.generated_rancher_key.key_name}.pem"
  sensitive_content = tls_private_key.rancher_ssh_key.private_key_pem
}

# data "local_file" "rancher_pem" {
#   filename = "files\\${aws_key_pair.generated_rancher_key.key_name}.pem"
#   depends_on = [
#     aws_key_pair.generated_rancher_key,
#     local_file.rancher_pem_file
#   ]
# }

resource "aws_instance" "rancher_master" {
  count = var.instances.rancher_master.count
  tags = {
    Name        = "${var.prefix}-rancher-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = aws_key_pair.generated_rancher_key.key_name
  ami                         = module.ami.leap-15_SP3
  instance_type               = var.instances.rancher_master.type
  associate_public_ip_address = "true"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.default_sg
  source_dest_check           = "false"
  
  # foreach = aws_instance.rancher_master
  # private_ips = slice(aws_instance.rancher_master[count.index].private_ip, 0, each.value.private_ip)
  # private_ips = slice(aws_instance.rancher_master[*].private_ip, 1, length(aws_instance.rancher_master))

  #  value       = element(concat(aws_instance.rancher_master.*.public_ip [""]), 0)
# "${element(aws_instance.rancher_master.*.public_ip, count.index)}"

  # user_data                   = base64encode(templatefile("${path.module}/files/user-data-rancher.yml", { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}", private_ip = "${slice(aws_instance.rancher_master[count.index].private_ip, 0, length(aws_instance.rancher_master))}", public_ip = "${slice(aws_instance.rancher_master[count.index].public_ip, 0, length(aws_instance.rancher_master))}" }))
  # user_data                   = base64encode(templatefile("${path.module}/files/user-data-rancher.yml", { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}", private_ip = "${element(aws_instance.rancher_master.*.private_ip, count.index)}" , public_ip = "${element(aws_instance.rancher_master.*.public_ip, count.index)}" }))
  user_data                   = base64encode(templatefile("${path.module}/files/user-data-rancher.yml", { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}" }))


  root_block_device {
    volume_size = var.instances.rancher_master.volume_size
  }
  credit_specification {
    cpu_credits = "standard"
  }
}

# data "external" "rancher_kubeconfig" {
#   # program = [ "bash", "cat /etc/rancher/k3s/k3s.yaml" ]
#   program = [ "bash", "/usr/local/bin/get-kubeconfig.sh" ]
#   depends_on = [
#     aws_instance.rancher_master
#   ]
# }

resource "local_file" "kube_config_local_yaml" {
  filename = format("%s/%s", path.root, "kube_config_local.yaml") 
#  content = data.external.rancher_kubeconfig.result 
  content = sshcommand_command.retrieve_config.result 
  # depends_on = [
  #   data.external.rancher_kubeconfig
  # ]
  depends_on = [
    sshcommand_command.retrieve_config
  ]
}

provider "rancher2" {
  alias     = "bootstrap"
  insecure  = true
  api_url   = "https://${aws_instance.rancher_master[0].public_ip}.nip.io"
  # api_url   = "https://${var.rancher-hostname}"
  # api_url   = "https://${data.aws_instance.rancher_master.public_ip}.nip.io"
  bootstrap = true
  timeout   = "300s"
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  # depends_on = [var.dependency]
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
  # api_url   = "https://${var.rancher-hostname}"
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

# resource "local_file" "kube_config_local_yaml" {
#   filename = format("%s/%s", path.root, "kube_config_local.yaml")
#   # content  = data.rancher2_cluster.local.kube_config
#   # content  = rancher2_cluster_sync.wait_for_catalogs.kube_config
#   count      = length(aws_instance.rancher_master)
#   content    = sshcommand_command.retrieve_config.*.result[0]
#   # depends_on = [
#   #   helm_release.rancher_server
#   # ]
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

resource "rancher2_cluster_sync" "wait_for_catalogs" {
  cluster_id      = "local"
  provider        = rancher2.admin
  # wait_alerting   = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  # wait_monitoring = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  wait_catalogs   = true
}

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
  kubernetes_version = "v1.21.5+rke2r2"
}

# Save kubeconfig file for interacting with the local and downstream clusters from your local machine

resource "local_file" "kube_config_downstream_yaml" {
  filename = format("%s/%s", path.root, "kube_config_downstream.yaml")
  content  = rancher2_cluster_v2.rke2_win_cluster.kube_config
  depends_on = [
    helm_release.rancher_server
  ]
}