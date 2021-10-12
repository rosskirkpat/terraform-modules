# Configure the Rancher2 provider
provider "rancher2" {
  api_url    = var.rancher_api_endpoint
  token_key  = var.rancher_api_token
  insecure   = true
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_integer" "cluster_name_append" {
  min = 1
  max = 99999
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${var.rancher-hostname}"
  bootstrap = true
  timeout   = "240s"
}


# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  depends_on = [var.dependency]
  provider   = rancher2.bootstrap
  password = random_password.password.result
  telemetry  = true
}

# Provider config for admin
provider "rancher2" {
  alias     = "admin"
  api_url   = "https://${var.rancher-hostname}"
  token_key = rancher2_bootstrap.admin.token
  insecure = true
}

resource "rancher2_setting" "server-url" {
  provider = rancher2.admin
  name     = "server-url"
  value    = "https://${var.rancher-hostname}"
}

resource "rancher2_token" "rancher-token" {
  provider    = rancher2.admin
  description = "Terraform ${var.owner}-${var.rancher_cluster_name} token"
}

# Create a new rancher2 resource using admin provider config
resource "rancher2_catalog" "rancher" {
  provider = rancher2.admin
  name     = "rancher"
  version  = "helm_v3"
  url      = "https://releases.rancher.com/server-charts/latest"
}

#
# Rancher backup
#
resource "rancher2_app_v2" "rancher-backup" {
  provider   = rancher2.admin
  cluster_id = "local"
  name       = "rancher-backup"
  namespace  = "cattle-resources-system"
  repo_name  = "rancher-charts"
  chart_name = "rancher-backup"
}

resource "rancher2_cluster_sync" "wait-for-monitoring" {
  cluster_id      = "local"
  provider        = rancher2.admin
  wait_alerting   = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  wait_monitoring = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  wait_catalogs   = true
}

data "rancher2_role_template" "admin" {
  depends_on = [rancher2_catalog.rancher]
  provider   = rancher2.admin
  name       = "Cluster Owner"
}

# downstream cluster
resource "rancher2_cluster_v2" "rke2_win_cluster" {
  name = "${var.rancher_cluster_name}${random_integer.cluster_name_append.result}"
  # description = "RKE2 Windows Cluster"
  fleet_namespace = "fleet-default"
  kubernetes_version = "v1.21.5+rke2r2"
}

### OUTPUT 

output "rancher2_url" {
      url = random_password.password.result
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_password" {
      pw = random_password.password.result
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "downstream_cluster" {
      cluster_name = rancher2_cluster_v2.rke2_win_cluster.name
      depends_on = [
        rancher2_cluster_v2.rke2_win_cluster
      ]
}