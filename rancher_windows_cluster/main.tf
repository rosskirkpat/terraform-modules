# Configure the AWS Provider

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

# Load in the modules

module "networking" {
  source = "./modules/networking"

  vpc_id = var.vpc_id
  vpc_name = var.vpc_name
  sg_id = var.sg_id
  subnet_id = var.subnet_id
  subnet_cidr_block = var.subnet_cidr_block
  subnet_tag_name = var.subnet_tag_name
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


################################## Rancher
resource "rancher2_cluster" "windows_cluster" {
  name = var.rancher_cluster_name
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
        "flannel_backend_vni" = 4096
      }
    }
    services {
      etcd {
        creation = "6h"
        retention = "24h"
      }
    }
  }
  enable_cluster_monitoring = true
  windows_prefered_cluster = true


}

resource "aws_instance" "linux_master" {
  count = var.num_linux_master
  tags = {
    Name        = "var.prefix-master-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type		            = var.linux_master_instance_type
  associate_public_ip_address = "true"
  availability_zone           = var.availability_zone
  subnet_id                   = module.networking.subnet_id
  vpc_security_group_ids      = [module.networking.security_group_id]
  user_data                   = file(var.userdata_linux_file)

  root_block_device {
    volume_size = var.linux_master_volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ssh_user_linux
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
  count = var.num_linux_worker
  tags = {
    Name        = "var.prefix-worker-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type		            = var.linux_worker_instance_type
  associate_public_ip_address = "true"
  availability_zone           = var.availability_zone
  subnet_id                   = module.networking.subnet_id
  vpc_security_group_ids      = [module.networking.security_group_id]
  user_data                   = file(var.userdata_linux_file)

  root_block_device {
    volume_size = var.linux_worker_volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ssh_user_linux
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
  count = var.num_windows_worker
  tags = {
    Name        = "var.prefix-win-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
  }

  key_name                    = var.aws_key_name
  ami                         = module.ami.windows-2019
  instance_type		            = var.windows_worker_instance_type
  associate_public_ip_address = "true"
  availability_zone           = var.availability_zone
  subnet_id                   = module.networking.subnet_id
  vpc_security_group_ids      = [module.networking.security_group_id]
  get_password_data           = "true"
  user_data                   = file(var.userdata_windows_file)

  root_block_device {
    volume_size = var.windows_worker_volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type     = "ssh"
    user     = var.ssh_user_windows
    password = rsadecrypt(self.password_data, file(var.private_key_path))
    host     = self.public_ip  
    script_path = "/Windows/Temp/terraform_%RAND%.bat"    
  }

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.windows_node_command} --worker"
    ]
  }
}

data "template_file" "decrypted_keys" {
  count = length(aws_instance.windows_worker)
  template = rsadecrypt(element(aws_instance.windows_worker.*.password_data, count.index), file(var.private_key_path))
}
