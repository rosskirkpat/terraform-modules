# Configure the AWS Provider

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

# Load in the modules
module "networking" {
  source          = "./modules/networking"
  cluster_id      = var.rancher_cluster_name
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
    cloud_provider {
      name = "aws"
    }
    network {
      plugin = "flannel"
      options = {
        "flannel_backend_type" = "host-gw"
      }
    }
#    kubernetes_version = var.k8s_version
    kubernetes_version = "v1.19.7-rancher1-1"
    services {
      etcd {
        creation  = "6h"
        retention = "24h"
      }
      kubeproxy {
        extra_args = {
          v = 6
        }
      }
      kubelet {
        extra_args = {
          v = 6
        }
      }
      kube_controller {
        extra_args = {
          v = 6
        }
      }
      kube_api {
        extra_args = {
          v = 6
        }
      }
    }
  }
  enable_cluster_monitoring = true
  windows_prefered_cluster  = true
}

resource "aws_instance" "linux_cp" {
  count = var.instances["linux_cp"].count
  tags = {
    Name        = "${var.prefix}-cp-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "owned"
  }

  iam_instance_profile        = var.aws_profile_name
  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_cp"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_cp"].userdata_file)
  source_dest_check           = "false"

  root_block_device {
    volume_size = var.instances["linux_cp"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instances["linux_cp"].ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\"",
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.node_command}  --controlplane"
    ]
  }
}

resource "aws_instance" "linux_all" {
  count = var.instances["linux_all"].count
  tags = {
    Name        = "${var.prefix}-all-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "owned"
  }

  iam_instance_profile        = var.aws_profile_name
  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_all"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_all"].userdata_file)
  source_dest_check           = "false"

  root_block_device {
    volume_size = var.instances["linux_all"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instances["linux_all"].ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\"",
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.node_command}  --controlplane --etcd --worker"
    ]
  }
}

resource "aws_instance" "linux_etcd" {
  count = var.instances["linux_etcd"].count
  tags = {
    Name        = "${var.prefix}-etcd-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "owned"
  }

  iam_instance_profile        = var.aws_profile_name
  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_etcd"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_etcd"].userdata_file)
  source_dest_check           = "false"

  root_block_device {
    volume_size = var.instances["linux_etcd"].volume_size
  }

  credit_specification {
    cpu_credits = "standard"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instances["linux_etcd"].ssh_user
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash -c \"timeout 300 sed '/finished-user-data/q' <(tail -f /var/log/cloud-init-output.log)\"",
      "${rancher2_cluster.windows_cluster.cluster_registration_token.0.node_command} --etcd"
    ]
  }
}

resource "aws_instance" "linux_worker" {
  count = var.instances["linux_worker"].count
  tags = {
    Name        = "${var.prefix}-worker-${count.index}"
    Owner       = var.owner
    DoNotDelete = "true"
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "owned"
  }

  iam_instance_profile        = var.aws_profile_name
  key_name                    = var.aws_key_name
  ami                         = module.ami.ubuntu-18_04
  instance_type               = var.instances["linux_worker"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[0]
  vpc_security_group_ids      = module.networking.security_group_ids
  user_data                   = file(var.instances["linux_worker"].userdata_file)
  source_dest_check           = "false"

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
    "kubernetes.io/cluster/${var.rancher_cluster_name}" : "owned"
  }

  iam_instance_profile        = var.aws_profile_name
  key_name                    = var.aws_key_name
  ami                         = module.ami.windows-${var.windows_build}
  instance_type               = var.instances["windows_worker"].type
  associate_public_ip_address = "true"
  subnet_id                   = module.networking.subnet_ids[1]
  vpc_security_group_ids      = module.networking.security_group_ids
  get_password_data           = "true"
  user_data                   = file(var.instances["windows_worker"].userdata_file)
  source_dest_check           = "false"

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
