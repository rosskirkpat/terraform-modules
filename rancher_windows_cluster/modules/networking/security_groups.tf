# resource "aws_default_security_group" "default" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port = 0
#     to_port   = 0
#     protocol  = -1
#     self      = true
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }

# resource "aws_security_group" "all" {
#   name   = "all"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "kubernetes.io/cluster/${var.cluster_id}" : "owned"
#   }
# }
