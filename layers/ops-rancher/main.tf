provider "aws" {
  region = var.region
}

provider "rancher2" {
  alias      = "rancher"
  api_url    = "https://${data.terraform_remote_state.ops.outputs.rancher-hostname}"
  access_key = module.rancher-bootstrap.access-key
  secret_key = module.rancher-bootstrap.secret-key
}

#
# Set the layer from tags
#
locals {
  layer = lookup(var.tags, "layer", null)
}

module "rancher-password" {
  source = "../../modules/password"
}

#
# Boostrap rancher
#
module "rancher-bootstrap" {
  name             = var.name
  source           = "../../modules/rancher-bootstrap"
  layer            = local.layer
  rancher-hostname = data.terraform_remote_state.ops.outputs.rancher-hostname
  rancher-password = module.rancher-password.password
  tags             = var.tags
}

#
# Rancher catalog
#
resource "rancher2_catalog" "rancher" {
  provider = rancher2.rancher
  name     = "rancher"
  version  = "helm_v3"
  url      = "https://releases.rancher.com/server-charts/latest"
}

#
# Rancher backup
#
resource "rancher2_app_v2" "rancher-backup" {
  provider   = rancher2.rancher
  cluster_id = "local"
  name       = "rancher-backup"
  namespace  = "cattle-resources-system"
  repo_name  = "rancher-charts"
  chart_name = "rancher-backup"
}

#
# Enable cluster monitoring (on existing local cluster)
#
data "rancher2_project" "system" {
  depends_on = [rancher2_catalog.rancher]
  provider   = rancher2.rancher
  cluster_id = "local"
  name       = "System"
}

resource "null_resource" "enable_cluster_monitoring" {
  count      = var.monitoring-feature == "1" && var.monitoring-enabled ? 1 : 0
  depends_on = [rancher2_catalog.rancher]
  provisioner "local-exec" {
    command = <<-EOF
    curl -su "${module.rancher-bootstrap.access-key}:${module.rancher-bootstrap.secret-key}" -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' \
    -d '{"answers":{"exporter-node.enabled":"true", "exporter-node.resources.limits.memory":"400Mi", "exporter-node.ports.metrics.port":"9796", "operator.resources.limits.memory":"1000Mi", "grafana.persistence.enabled":"false", "prometheus.resources.core.limits.memory":"3000Mi", "prometheus.persistence.size":"32Gi", "prometheus.persistence.enabled":"true", "prometheus.persistence.storageClass":"ebs-sc", "prometheus.retention":"720h"}, "version":null}' \
    'https://${data.terraform_remote_state.ops.outputs.rancher-hostname}/v3/clusters/local?action=enableMonitoring'
    EOF
  }
}

#
# Wait for cluster
#
resource "rancher2_cluster_sync" "wait-for-monitoring" {
  cluster_id      = "local"
  provider        = rancher2.rancher
  wait_alerting   = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  wait_monitoring = var.monitoring-feature == "1" && var.monitoring-enabled ? true : null
  wait_catalogs   = true
}

#
# Rancher monitoring v2
#
module "rancher-monitoring" {
  name                    = var.name
  layer                   = local.layer
  region                  = var.region
  source                  = "../../modules/rancher-monitoring"
  ops-rancher-hostname    = data.terraform_remote_state.ops.outputs.rancher-hostname
  cluster-id              = "local"
  project-id              = rancher2_cluster_sync.wait-for-monitoring.id
  dependency              = rancher2_cluster_sync.wait-for-monitoring
  enabled                 = var.monitoring-feature == "2" && var.monitoring-enabled ? true : false
  monitoring-ver          = var.monitoring-ver
  prometheus-retention    = var.prometheus-retention
  prometheus-memory-limit = var.prometheus-memory-limit
  prometheus-volume-size  = var.prometheus-volume-size
  pagerduty-service-key   = data.aws_ssm_parameter.pagerduty-service-key.value
  access-key              = module.rancher-bootstrap.access-key
  secret-key              = module.rancher-bootstrap.secret-key
}

module "rancher-alerts" {
  name                  = var.name
  region                = var.region
  source                = "../../modules/rancher-alerts"
  ops-rancher-hostname  = data.terraform_remote_state.ops.outputs.rancher-hostname
  enabled               = var.monitoring-feature == "1" && var.monitoring-enabled ? true : false
  cluster-id            = rancher2_cluster_sync.wait-for-monitoring.id
  pagerduty-service-key = data.aws_ssm_parameter.pagerduty-service-key.value
  access-key            = module.rancher-bootstrap.access-key
  secret-key            = module.rancher-bootstrap.secret-key
}

data "rancher2_role_template" "admin" {
  depends_on = [rancher2_catalog.rancher]
  provider   = rancher2.rancher
  name       = "Cluster Owner"
}
