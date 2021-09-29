# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
  default_tags {
    tags = {
      Owner       = var.owner
      DoNotDelete = "true"
    }
  }
}

# Load in the modules
module "networking" {
  source = "./modules/networking"
  vpc_name = var.vpc_name
  sg_name  = var.sg_name
  owner    = var.owner
}

module "ami" {
  source = "./modules/ami"
}

# Configure the Rancher2 provider
provider "rancher2" {
  api_url    = var.rancher_api_endpoint
  token_key  = var.rancher_api_token
  insecure = true
}


resource "random_integer" "cluster_name_append" {
  min = 1
  max = 99999
}
################################## Rancher
resource "rancher2_cluster_v2" "rke2_win_cluster" {
  name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  # description = "RKE2 Windows Cluster"
  fleet_namespace = "fleet-default"
  kubernetes_version = "v1.21.4+rke2r3"
  }

resource "aws_instance" "linux_master" {
  count = var.instances.linux_master.count
  tags = {
    Name        = "${var.prefix}-master-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-20_04
  instance_type               = var.instances.linux_master.type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.target_sg
  user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_node_command}"," --etcd --controlplane") }))

  root_block_device {
    volume_size = var.instances.linux_master.volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_instance" "linux_worker" {
  count = var.instances.linux_worker.count
  tags = {
    Name        = "${var.prefix}-worker-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-20_04
  instance_type		            = var.instances.linux_worker.type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.target_sg
  user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_node_command}"," --worker") }))

  root_block_device {
    volume_size = var.instances.linux_worker.volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_instance" "windows_worker" {
  count = var.instances.windows_worker.count
  tags = {
    Name        = "${var.prefix}-win-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.windows-2019
  instance_type		            = var.instances.windows_worker.type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.target_sg
  get_password_data           = "true"
  user_data                   = base64encode(templatefile("files/user-data-windows.yml", { cluster_registration = format("%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_windows_node_command}") }))
  # user_data                   = base64encode(templatefile("files/user-data-windows.yml", { cluster_registration = format("%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_windows_node_command}"), api_endpoint = "${var.rancher_api_endpoint}" }))

  root_block_device {
    volume_size = var.instances.windows_worker.volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

data "template_file" "decrypted_keys" {
  count = length(aws_instance.windows_worker)
  template = rsadecrypt(element(aws_instance.windows_worker.*.password_data, count.index), file(var.private_key_path))
}
