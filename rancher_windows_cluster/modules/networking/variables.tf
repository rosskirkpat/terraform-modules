# networking

variable "vpc_name" {
  description = "aws vpc name"
  default     = ""
}

variable "sg_name" {
  description = "aws security group name"
  default     = ""
}

variable "owner" {
  description = "Owner tag value for AWS instances"
  default     = ""
}

variable "vpc_domain_name" {
  description = "aws dhcp options domain name(s)"
  default     = ""
}

variable "cluster_id" {
  description = "cluster id to use in tagging resources for aws cloud provider"
  default     = ""
}
