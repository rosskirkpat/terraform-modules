terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
