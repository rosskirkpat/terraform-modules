

locals {
  # Use existing (via data source) or create new zone (will fail validation, if zone is not reachable)
  use_existing_route53_zone = true

  domain = "terraform-aws-modules.modules.tf"

  # Removing trailing dot from domain - just to be sure :)
  domain_name = trimsuffix(local.domain, ".")
}

data "aws_route53_zone" "this" {
  count = local.use_existing_route53_zone ? 1 : 0

  name         = local.domain_name
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = !local.use_existing_route53_zone ? 1 : 0
  name  = local.domain_name
}

module "acm" {
  source = "../../"
  version = "~> 3.0"
#   control whether to create certs or not 
#   create_certificate = false

  domain_name = local.domain_name
  zone_id     = coalescelist(data.aws_route53_zone.this.*.zone_id, aws_route53_zone.this.*.zone_id)[0]

  subject_alternative_names = [
    "*.${local.domain_name}",
    "rancher.${local.domain_name}",
  ]

  # Disable DNS validation
#   validate_certificate = false
  wait_for_validation = true

  tags = {
    Name = local.domain_name
  }
}


module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name  = "my-domain.com"
  zone_id      = "Z2ES7B9AZ6SHAE"

  subject_alternative_names = [
    "*.my-domain.com",
    "app.sub.my-domain.com",
  ]


  wait_for_validation = true

  tags = {
    Name = "my-domain.com"
  }
}
