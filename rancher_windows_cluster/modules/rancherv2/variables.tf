# Required

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.5.3"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.21.5+k3s2"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format v0.0.0)"
  default     = "v2.6.2"
}

# variable "admin_password" {
#   type        = string
#   description = "Admin password to use for Rancher server bootstrap"
# }

variable "rancher-hostname" {
  type        = string
  description = "Rancher server hostname"
#   default = "https://${data.aws_instance.rancher_master[0].public_ip}.nip.io"
}