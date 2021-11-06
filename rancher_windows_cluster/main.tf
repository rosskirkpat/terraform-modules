# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

resource "random_integer" "cluster_name_append" {
  min = 1
  max = 99999
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "tf-downstream-${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "pem_file" {
  filename = format("%s/%s", "${path.root}/keys", "${aws_key_pair.generated_key.key_name}.pem") 
  sensitive_content = tls_private_key.ssh_key.private_key_pem
}

# Load in the modules
module "aws_vpc_create" {
  source               = "./modules/aws_vpc_create"
  vpc_name             = var.vpc_name
  owner                = var.owner
  rancher_cluster_name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  vpc_domain_name      = var.vpc_domain_name
}

module "ami" {
  source = "./modules/ami"
}

module "rancherv2" {
  source = "./modules/rancherv2"
  # vpc_name             = var.vpc_name
  owner                = var.owner
  rancher_cluster_name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  # vpc_domain_name      = var.vpc_domain_name
  prefix               = var.prefix
  subnet_id            = module.aws_vpc_create.subnet_ids[0]
  default_sg           = [module.aws_vpc_create.default_security_group_id]
  vpc_id               = module.aws_vpc_create.vpc_id
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  # region     = var.aws_region
}

# Configure the Rancher2 provider
provider "rancher2" {
  api_url    = module.rancherv2.rancher2_url
  token_key  = module.rancherv2.rancher2_token
  # api_url    = var.rancher_api_endpoint
  # token_key  = var.rancher_api_token
  insecure   = true
}
# resource "rancher2_cluster_v2" "rke2_win_cluster" {
#   name               = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
#   fleet_namespace    = "fleet-default"
#   kubernetes_version = "v1.21.5+rke2r2"
#   }

resource "aws_instance" "linux_master" {
  count = var.instances.linux_master.count
  tags = {
    Name        = "${var.prefix}-master-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = aws_key_pair.generated_key.key_name
  ami                         = module.ami.ubuntu-20_04
  instance_type               = var.instances.linux_master.type
  associate_public_ip_address = "true"
  subnet_id                   = module.aws_vpc_create.subnet_ids[0]
  vpc_security_group_ids      = [module.aws_vpc_create.default_security_group_id]
  source_dest_check           = "false"
  # user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_node_command}"," --etcd --controlplane") }))
  user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --etcd --controlplane") }))



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

  key_name                    = aws_key_pair.generated_key.key_name
  ami                         = module.ami.ubuntu-20_04
  instance_type		            = var.instances.linux_worker.type
  associate_public_ip_address = "true"
  subnet_id                   = module.aws_vpc_create.subnet_ids[0]
  vpc_security_group_ids      = [module.aws_vpc_create.default_security_group_id]
  source_dest_check           = "false"
  # user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_node_command}"," --worker") }))
  user_data                   = base64encode(templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --worker") }))


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

  key_name                    = aws_key_pair.generated_key.key_name
  ami                         = module.ami.windows-2019
  instance_type		            = var.instances.windows_worker.type
  associate_public_ip_address = "true"
  subnet_id                   = module.aws_vpc_create.subnet_ids[0]
  vpc_security_group_ids      = [module.aws_vpc_create.default_security_group_id]
  get_password_data           = "true"
  source_dest_check           = "false"
  # user_data                   = base64encode(templatefile("files/user-data-windows.yml", { cluster_registration = format("%s","${rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token[0].insecure_windows_node_command}") }))
  user_data                   =  base64encode(templatefile("files/user-data-windows.yml", { cluster_registration = format("%s",module.rancherv2.insecure_rke2_cluster_windows_command)}))

  root_block_device {
    volume_size = var.instances.windows_worker.volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

data "template_file" "decrypted_keys" {
  count = length(aws_instance.windows_worker)
  template = rsadecrypt(element(aws_instance.windows_worker.*.password_data, count.index), tls_private_key.ssh_key.private_key_pem)
}
