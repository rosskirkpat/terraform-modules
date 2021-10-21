# Configure the Rancher2 provider
# provider "rancher2" {
#   api_url    = var.rancher_api_endpoint
#   token_key  = var.rancher_api_token
#   insecure   = true
# }

# Load in the modules
module "aws_vpc_create" {
  source               = "../aws_vpc_create"
}

module "ami" {
  source = "../ami"
}


resource "random_password" "rancher_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_integer" "rancher_name_append" {
  min = 1
  max = 99999
}

resource "tls_private_key" "rancher_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_rancher_key" {
  key_name   = "terraform-rancher-local-cluster-key-pair-${random_integer.rancher_name_append.result}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "rancher_pem_file" {
  filename = "files\\${aws_key_pair.generated_rancher_key.key_name}.pem"
  sensitive_content = tls_private_key.rancher_ssh_key.private_key_pem
}

resource "aws_instance" "rancher_master" {
  count = 3
  tags = {
    Name        = "${var.prefix}-master-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = aws_key_pair.generated_rancher_key.key_name
  ami                         = module.ami.leap-15_SP3
  instance_type               = var.instances.linux_master.type
  associate_public_ip_address = "true"
  subnet_id                   = module.aws_vpc_create.subnet_ids[0]
  vpc_security_group_ids      = [module.aws_vpc_create.default_security_group_id]
  source_dest_check           = "false"
  user_data                   = base64encode(templatefile("user-data-rancher.yml", { public_ip = format("%s,${data.aws_instance.rancher_master.public_ip}"), private_ip = format("%s,${data.aws_instance.rancher_master.private_ip}"), k8s_version = format("%s,${var.rancher_kubernetes_version}") }))

  root_block_device {
    volume_size = var.instances.linux_master.volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    config_path = local_file.kube_config_server_yaml.filename
  }
}

provider "rancher2" {
  alias     = "bootstrap"
  insecure  = true
  api_url   = "https://${data.aws_instance.rancher_master[0].public_ip}.nip.io"
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
  api_url   = rancher2.bootstrap.api_url
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}

resource "rancher2_setting" "server-url" {
  provider = rancher2.admin
  name     = "server-url"
  value    = "https://${var.rancher-hostname}"
}

resource "rancher2_token" "rancher-token" {
  provider    = rancher2.admin
  description = "Terraform ${var.owner}-${var.rancher_cluster_name} token"
}

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

# resource "rancher2_cluster_sync" "wait-for-monitoring" {
#   cluster_id      = "local"
#   provider        = rancher2.admin
#   wait_alerting   = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
#   wait_monitoring = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
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
  kubernetes_version = "v1.21.5+rke2r2"
}
