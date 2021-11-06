# Helm resources

# Install cert-manager helm chart
resource "helm_release" "cert_manager" {
  depends_on = [
    aws_instance.rancher_master,
    sshcommand_command.retrieve_config,
    local_file.kube_config_local_yaml
  ]
  repository       = "https://charts.jetstack.io"
  name             = "cert-manager"
  chart            = "cert-manager"
  version          = "v${var.cert_manager_version}"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}


# Install Rancher helm chart
resource "helm_release" "rancher_server" {
  depends_on = [
    helm_release.cert_manager
  ]

  repository       = "https://releases.rancher.com/server-charts/stable"
  name             = "rancher"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true
#   wait_for_jobs    = true
#   reuse_values     = true
  timeout          = 300

  set {
    name  = "hostname"
    value = "${aws_instance.rancher_master[0].public_ip}.nip.io"
  }

  set {
    name  = "replicas"
    value = "1"
  }
  set {
    name = "bootstrapPassword"
    value = "admin"
  }
}
