# Required

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.5.3"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.21.6+k3s1"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format v0.0.0)"
  default     = "v2.6.2"
}

# variable "admin_password" {
#   type        = string
#   description = "Admin password to use for Rancher server bootstrap"
# }

# variable "rancher-hostname" {
#   type        = string
#   description = "Rancher server hostname"
# #   default = "https://${data.aws_instance.rancher_master[0].public_ip}.nip.io"
# }

# variable "vpc_name" {
#   description = "aws vpc name"
# }

# variable "vpc_domain_name" {
#   description = "aws dhcp options domain name(s)"
# }

variable "rancher_cluster_name" {
  description = "cluster name to use in tagging resources for aws cloud provider"
}

variable "owner" {
}

variable "prefix" {
}

variable "default_sg" {
}

variable "subnet_id" {
}

variable "vpc_id" {
}

#ec2 instances
variable "instances" {
  type = map(object({
    count       = number
    type        = string
    ssh_user    = string
    volume_size = number
  }))
  default = {
    rancher_master = {
      count       = 3
      type        = "m5.xlarge"
      ssh_user    = "rancher"
      volume_size = 150
    }
  }
}

variable "vpc_id" {
}
