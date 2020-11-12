output "vpc_id" {
  value = var.vpc_id
}

output "subnet_id" {
#  value = [data.aws_subnet_ids.selected.ids]
  value = var.subnet_id
}

output "security_group_id" {
  value = var.sg_id
}

output "sn_cidr_block" {
  value = var.subnet_cidr_block
}
