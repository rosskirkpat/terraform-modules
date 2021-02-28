variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-west-2"
}

variable "aws_key_name" {
  type        = string
  description = "AWS Key used for all resources"
}

variable "aws_profile_name" {
  type    = string
  default = ""
}
variable "private_key_path" {
  type        = string
  description = "local private key path for AWS key used to ssh to linux and decrypt windows passwords"
}

variable "vpc_name" {
  description = "aws vpc name"
}

variable "vpc_domain_name" {
  description = "AWS VPC Domain Names for DHCP Options Sets, if empty AWS will auto-create"
  default     = ""
}

variable "owner" {
  type        = string
  description = "Owner tag value for AWS instances"
}

variable "prefix" {
  type        = string
  description = "Prefix for Name tag of instances"
  default     = ""
}

# variables to inject into the ec2 provider

variable "choose_windows_build" {
  type        = string
  description = "Windows Build Version to Use. Options (1809-ui 1809-core 1909 2004 20H2)"
  default     = "2004"
}

variable "use_dhcp_options_sets" {
  type        = boolean
  description = "Whether to create DHCP Options Sets for AWS VPC"
  default     = false
}

#ec2 instances
variable "instances" {
  type = map(object({
    count         = number
    type          = string
    ssh_user      = string
    volume_size   = number
    userdata_file = string
  }))
  default = {
    linux_all = {
      count         = 1
      type          = "m5.xlarge"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    linux_etcd = {
      count         = 0
      type          = "m5.large"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    linux_cp = {
      count         = 0
      type          = "m5.large"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    linux_worker = {
      count         = 0
      type          = "m5.xlarge"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    windows_worker = {
      count         = 3
      type          = "m5.xlarge"
      ssh_user      = "administrator"
      volume_size   = 150
      userdata_file = "./files/userdata_windows.txt"
    }
  }
}

# variables to inject into rancher2 provider

variable "enable_cloud_provider" {
  type        = boolean
  description = "Whether to enable the cloud provider"
  default     = false
}

variable "choose_cloud_provider" {
  type        = string
  description = "Which in-tree cloud provider to enable"
  default     = ""
  # validate answer to be either aws or vsphere 
}

variable "services_verbosity" {
  type        = string
  description = "Set desired verbosity level for all RKE services"
  # validate answer to only be a single numeral in range of 1-6
}

variable "choose_flannel_backend" {
  type        = string
  description = "Which flannel backend to use"
  default     = ""
  # validate answer to be either vxlan or host-gw
  # template for changes to make based on provided answer
}

variable "create_new_vpc" {
  type        = boolean
  description = "Whether to create a new vpc for the cluster being provisioned"
  default     = false 
}


# rancher2 provider variables
variable "rancher_api_endpoint" {
  type        = string
  description = "Endpoint for the Rancher API"
}

variable "rancher_api_token" {
  type        = string
  description = "API Token to access the Rancher API"
}

variable "rancher_cluster_name" {
  type        = string
  description = "Name of the rancher cluster that's being created"
}

variable "kubernetes_version" {
  type        = string
  description = "Desired Kubernetes Version"
  default     = ""
}
