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
  description = "AWS VPC Domain Names, if empty AWS will auto-create"
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
    linux_master = {
      count         = 1
      type          = "m5.xlarge"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    linux_worker = {
      count         = 1
      type          = "m5.large"
      ssh_user      = "ubuntu"
      volume_size   = 50
      userdata_file = "./files/userdata_linux.txt"
    }
    windows_worker = {
      count         = 1
      type          = "m5.xlarge"
      ssh_user      = "administrator"
      volume_size   = 150
      userdata_file = "./files/userdata_windows.txt"
    }
  }
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