provider "aws" {
  region = var.region
}

#
# Set the layer from tags
#
locals {
  layer = lookup(var.tags, "layer", null)
}

#
# VPC
#
module "vpc" {
  name        = var.name
  source      = "../../modules/vpc"
  cidr        = var.cidr
  azs         = var.azs
  natgw-count = var.natgw-count
  tags        = var.tags
}

# Import and remove rules from the default security group
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc-id
}
