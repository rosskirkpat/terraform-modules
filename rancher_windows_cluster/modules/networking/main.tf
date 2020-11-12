# networking

variable "vpc_id" {
  description = "vpc id for all resources"
}

variable "vpc_name" {
  description = "aws vpc name"
}

variable "sg_id" {
  description = "aws security group ID"
}

variable "subnet_id" {
  description = "aws security group ID"
}

variable "subnet_cidr_block" {
  description = "aws subnet cidr block"
}

variable "subnet_tag_name" {
  description = "name of the aws subnet"
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_security_group" "my_security_group" {
    vpc_id  = var.vpc_id
    id      = var.sg_id
}

data "aws_subnet_ids" "selected" {
    vpc_id            = var.vpc_id
  tags = {
    Name = var.subnet_tag_name
  }
}
