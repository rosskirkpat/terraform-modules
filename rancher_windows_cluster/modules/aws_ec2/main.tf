provider "aws" {
    region = local.region
  }
  
  locals {
    name   = "example-ec2-complete"
    region = "us-east-1"
  
    tags = {
      Owner       = var.owner
      DoNotDelete = "true"
    }
  }
  
  ################################################################################
  # EC2 Module - multiple instances with `for_each`
  ################################################################################
  
  locals {
    multiple_instances = {
      rancher_master = {
        instance_type     = "m5.large"
        availability_zone = element(module.aws_vpc.azs, 0)
        subnet_id         = element(module.aws_vpc.private_subnets, 0)
        volume_size = 150
        user_data   = "${data.template_file.cloud-config.rendered, { k3s_version = "${var.rancher_kubernetes_version}", public_key = "${tls_private_key.rancher_ssh_key.public_key_openssh}" , k3s_agent_token = "${module.rancherv2.k3s_agent_token}", k3s_token = "${module.rancherv2.k3s_token}")}}"
      }
      controlplane = {
        instance_type     = "m5.large"
        availability_zone = element(module.aws_vpc.azs, 1)
        subnet_id         = element(module.aws_vpc.private_subnets, 1)
        user_data                   = templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --controlplane") })
        volume_size = 50
      }
      etcd = {
        instance_type     = "m5.large"
        availability_zone = element(module.aws_vpc.azs, 2)
        subnet_id         = element(module.aws_vpc.private_subnets, 2)
        user_data                   = templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --etcd") })
        volume_size = 50
      }
      dual_master = {
        instance_type     = "m5.xlarge"
        availability_zone = element(module.aws_vpc.azs, 2)
        subnet_id         = element(module.aws_vpc.private_subnets, 2)
        user_data                   = templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --etcd --controlplane") })
        volume_size = 75
      }
      linux_worker = {
        instance_type     = "m5.xlarge"
        availability_zone = element(module.aws_vpc.azs, 0)
        subnet_id         = element(module.aws_vpc.private_subnets, 0)
        user_data                   = templatefile("files/user-data-linux.yml", { cluster_registration = format("%s%s",module.rancherv2.insecure_rke2_cluster_command," --worker") })
        volume_size = 50
      }
      windows_worker = {
        instance_type     = "m5.xlarge"
        availability_zone = element(module.aws_vpc.azs, 1)
        subnet_id         = element(module.aws_vpc.private_subnets, 1)
        user_data                   =  templatefile("files/user-data-windows.yml", { cluster_registration = format("%s",module.rancherv2.insecure_rke2_cluster_windows_command)})
        volume_size = 150
      }
    }
    root_block_devices = {
        rancher_master = {
            encrypted = false
            volume_type = 
            iops = 
            throughput = 
            kms_key_id = 
            volume_size = 
        }
        controlplane = {}
        etcd = {}
        dual_master = {}
        linux_worker = {}
        windows_worker = {}
    }
  }
  
  module "aws_ec2" {
    source = "modules/aws_ec2"
  
    for_each = local.multiple_instances
  
    name = "${local.name}-${each.key}"
  
    ami                    = each.value.ami
    instance_type          = each.value.instance_type
    availability_zone      = each.value.availability_zone
    subnet_id              = each.value.subnet_id
    vpc_security_group_ids = [module.aws_sg.security_group_id]
    associate_public_ip_address = true
    user_data_base64 = base64encode(each.value.user_data)
    key_name                    = aws_key_pair.generated_key.key_name
    source_dest_check           = "false"
    tags = local.tags
    root_block_device = [
        {
            encrypted   = each.value.encrypted
            volume_type = each.value.volume_type
            iops        = each.value.iops
            throughput  = each.value.throughput
            volume_size = each.value.volume_size
            kms_key_id  = each.value.kms_key_id
            tags = {
                Name = "${local.name}-root-block"
            }
        },
    ]
  }