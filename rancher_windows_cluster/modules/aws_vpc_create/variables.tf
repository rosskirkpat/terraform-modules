# networking

variable "vpc_name" {
  description = "aws vpc name"
}

variable "vpc_domain_name" {
  description = "aws dhcp options domain name(s)"
}

variable "rancher_cluster_name" {
  description = "cluster name to use in tagging resources for aws cloud provider"
}

variable "owner" {
}
