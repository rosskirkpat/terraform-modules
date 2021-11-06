### OUTPUTS 

output "vpc_id" {
  value = aws_vpc.main_vpc.id
  depends_on = [
    aws_internet_gateway.main_ig
  ]
}

# output "vpc_name" {
#   value = aws_vpc.main_vpc.tags_all.Name
#   depends_on = [
#     aws_internet_gateway.main_ig
#   ]
# }

# output "vpc_name2" {
#   value = aws_vpc.main_vpc.tags.Name
#   depends_on = [
#     aws_internet_gateway.main_ig
#   ]
# }

output "subnet_ids" {
  value = [
    aws_subnet.a.id,
    aws_subnet.b.id,
    aws_subnet.c.id,
  ]
}

output "vpc_default_security_group_id" {
  value = aws_default_security_group.sg_default.id
}

output "open_security_group_id" {
  value = aws_security_group.sg_all.id
}


output "default_security_group_id" {
  value = aws_security_group.sg_default.id
}