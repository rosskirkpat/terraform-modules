module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"
#   create_lb = false
  name = "my-nlb"

  load_balancer_type = "network"

  vpc_id  = var.vpc_id
  subnets = ["subnet-abcde012", "subnet-bcde012a"]

  access_logs = {
    bucket = "my-nlb-logs"
  }

#   target_groups = [
#     {
#       name_prefix      = "pref-"
#       backend_protocol = "TCP"
#       backend_port     = 80
#       target_type      = "ip"
#     }
#   ]

  target_groups = [
    {
      name_prefix        = "tu1-"
      backend_protocol   = "TCP_UDP"
      backend_port       = 81
      target_type        = "instance"
      preserve_client_ip = true
      tags = {
        tcp_udp = true
      }
    },
    {
      name_prefix      = "u1-"
      backend_protocol = "UDP"
      backend_port     = 82
      target_type      = "instance"
    },
    {
      name_prefix          = "t1-"
      backend_protocol     = "TCP"
      backend_port         = 83
      target_type          = "ip"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthz"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }
    },
    {
      name_prefix      = "t2-"
      backend_protocol = "TLS"
      backend_port     = 84
      target_type      = "instance"
    },
  ]
}

  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}
