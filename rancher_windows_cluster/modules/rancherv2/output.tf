
### OUTPUT 

output "rancher2_local_cluster_nodes" {
    node_ip = [aws_instance.rancher_master[*].public_ip]
}

output "rancher2_url" {
      url = rancher2_bootstrap.admin.url
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_admin_user" {
      admin_user = rancher2_bootstrap.admin.user
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_token" {
      token = rancher2_bootstrap.admin.token
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_password" {
      admin_password = rancher2_bootstrap.admin.current_password
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

output "downstream_cluster_token" {
      token = rancher2_cluster_v2.rke2_win_cluster.token
      depends_on = [
        rancher2_cluster_v2.rke2_win_cluster
      ]
}

output "rke2_cluster_command" {
    value = rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token.0.insecure_node_command
    depends_on = [
      rancher2_cluster_v2.rke2_win_cluster
    ]
}

output "rke2_cluster_windows_command" {
    value = rancher2_cluster_v2.rke2_win_cluster.cluster_registration_token.0.insecure_windows_node_command
    depends_on = [
      rancher2_cluster_v2.rke2_win_cluster
    ]
}