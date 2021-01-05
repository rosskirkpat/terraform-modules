# networking

variable "vpc_name" {
  description = "aws vpc name"
  default = "main"
}

variable "vpc_domain_name" {
  description = "aws dhcp options domain name(s)"
  default = ""
}
