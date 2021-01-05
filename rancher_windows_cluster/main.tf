# Configure the AWS Provider

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

# Load in the modules
module "networking" {
  source = "./modules/networking"

  vpc_name        = var.vpc_name
  vpc_domain_name = var.vpc_domain_name
}

module "ami" {
  source = "./modules/ami"
}

# Configure the Rancher2 provider
provider "rancher2" {
  api_url   = var.rancher_api_endpoint
  token_key = var.rancher_api_token
  insecure  = true
}


################################## Rancher
resource "rancher2_cluster" "windows_cluster" {
  name        = var.rancher_cluster_name
  description = "Custom Rancher Windows Cluster with Monitoring"
  rke_config {
    # cloud_provider {
    # # aws_cloud_provider {
    #   name = "aws"
    #   # }
    # }
    network {
      plugin = "flannel"
      options = {
        "flannel_backend_port" = 4789
        "flannel_backend_type" = "vxlan"
        "flannel_backend_vni"  = 4096
      }
    }
    services {
      etcd {
        creation  = "6h"
        retention = "24h"
      }
    }
  }
  enable_cluster_monitoring = true
  windows_prefered_cluster  = true
}

resource "aws_instance" "linux_master" {
  count = var.instances["linux_master"].count
  tags = {
    Name        = "${var.prefix}-master-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_master"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_master"].userdata_file)

  root_block_device {
    volume_size = var.instances["linux_master"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instances["linux_master"].ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\"",
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.node_command} --etcd --controlplane"
    ]
  }
}

resource "aws_instance" "linux_worker" {
  count = var.instances["linux_worker"].count
  tags = {
    Name        = "${var.prefix}-worker-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_worker"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[1]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_worker"].userdata_file)

  root_block_device {
    volume_size = var.instances["linux_worker"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instances["linux_worker"].ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\"",
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.node_command} --worker"
    ]
  }
}
resource "aws_instance" "windows_worker" {
  count = var.instances["windows_worker"].count
  tags = {
    Name        = "${var.prefix}-win-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.windows-2019
  instance_type               = var.instances["windows_worker"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[2]
  vpc_security_group_ids      = module.networking.security_group_ids
  get_password_data           = "true"
  user_data                   = file(var.instances["windows_worker"].userdata_file)

  root_block_device {
    volume_size = var.instances["windows_worker"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    user        = var.instances["windows_worker"].ssh_user
    password    = rsadecrypt(self.password_data, file(var.private_key_path))
    host        = self.public_ip
    script_path = "/Windows/Temp/terraform_%RAND%.bat"
  }

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.windows_node_command} --worker"
    ]
  }
}

data "template_file" "decrypted_keys" {
  count    = length(aws_instance.windows_worker)
  template = rsadecrypt(element(aws_instance.windows_worker.*.password_data, count.index), file(var.private_key_path))
}
