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
    helm = {
      source = "hashicorp/helm"
    }
    sshcommand = {
      source  = "invidian/sshcommand"
      version = "0.2.2"
    }
  }
  required_version = ">= 1.0.0"
}
