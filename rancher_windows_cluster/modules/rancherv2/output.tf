
### OUTPUT 

output "rancher2_local_cluster_node_ips" {
    value = aws_instance.rancher_master[*].public_ip
}

output "rancher2_url" {
      value = rancher2_bootstrap.admin.url
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_admin_user" {
      value = rancher2_bootstrap.admin.user
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_token" {
      value = rancher2_bootstrap.admin.token
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "rancher2_password" {
      value = rancher2_bootstrap.admin.current_password
      depends_on = [
        rancher2_bootstrap.admin
      ]
}

output "downstream_cluster" {
      value = rancher2_cluster_v2.rke2_win_cluster.name
      depends_on = [
        rancher2_cluster_v2.rke2_win_cluster
      ]
}

# output "downstream_cluster_token" {
#       value = rancher2_cluster_v2.rke2_win_cluster.token
#       depends_on = [
#         rancher2_cluster_v2.rke2_win_cluster
#       ]
# }

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

output "rancher_kubeconfig" {
#   value = data.external.rancher_kubeconfig.result 
    value = sshcommand_command.retrieve_config.result
}