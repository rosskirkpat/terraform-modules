# networking

variable "vpc_name" {
  description = "aws vpc name"
  default     = "main"
}

variable "vpc_domain_name" {
  description = "aws dhcp options domain name(s)"
  default     = ""
}

variable "cluster_id" {
  description = "cluster id to use in tagging resources for aws cloud provider"
  default     = ""
}