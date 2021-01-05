output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [
    aws_subnet.a.id,
    aws_subnet.b.id,
    aws_subnet.c.id,
  ]
}

output "security_group_ids" {
  value = [
    aws_security_group.all.id,
    aws_default_security_group.default.id,
  ]
}
