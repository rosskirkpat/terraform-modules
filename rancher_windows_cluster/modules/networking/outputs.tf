output "vpc_id" {
  value = data.aws_vpc.target_vpc.id
}

# output "subnet_ids" {
#   value = [
#     aws_subnet.a.id,
#     aws_subnet.b.id,
#     aws_subnet.c.id,
#   ]
# }
# output "subnet_ids" {
#   # value = ["${element(data.aws_subnet_ids.target_subnet_ids.ids, count.index)}"]
#   value = data.aws_subnet_ids.target_subnets.*.id
# }

output "subnet_ids" {
  value = data.aws_subnet.target_subnets.*.id
}

output "target_sg" {
  value = data.aws_security_groups.target_sg.ids
}

# output "security_group_ids" {
#   value = [
#     aws_security_group.all.id,
#     aws_default_security_group.default.id,
#   ]
# }
