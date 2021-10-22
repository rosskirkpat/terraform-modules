variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-1"
}

variable "aws_profile_name" {
  type    = string
  default = null
}

variable "vpc_name" {
  description = "aws vpc name to be created"
  default = null
}

variable "vpc_domain_name" {
  description = "AWS VPC Domain Names, if empty AWS will auto-create"
  default     = null
}

variable "owner" {
  type        = string
  description = "Owner tag value for AWS instances"
}

variable "prefix" {
  type        = string
  description = "Prefix for Name tag of instances"
  default     = null
}

variable "aws_secret_key"{
  type        = string
}

variable "aws_access_key"{
  type        = string
}

#ec2 instances
variable "instances" {
  type = map(object({
    count         = number
    type          = string
    ssh_user      = string
    volume_size   = number
  }))
  default = {
    linux_master = {
      count         = 3
      type          = "m5.xlarge"
      ssh_user      = "ubuntu"
      volume_size   = 50
    }
    linux_worker = {
      count         = 1
      type          = "m5.large"
      ssh_user      = "ubuntu"
      volume_size   = 50
    }
    windows_worker = {
      count         = 1
      type          = "m5.xlarge"
      ssh_user      = "administrator"
      volume_size   = 100
    }
  }
}

# rancher2 provider variables
# variable "rancher_api_endpoint" {
#   type        = string
#   description = "Endpoint for the Rancher API"
# }

# variable "rancher_api_token" {
#   type        = string
#   description = "API Token to access the Rancher API"
# }

variable "rancher_cluster_name" {
  type        = string
  description = "Name of the rancher cluster that's being created"
}