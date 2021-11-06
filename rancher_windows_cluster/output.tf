output "windows_worker_public_ips" {
  value = aws_instance.windows_worker[*].public_ip
}

output "windows_passwords" {
  value = data.template_file.decrypted_keys.*.rendered
}

output "linux_master_public_ips" {
  value = aws_instance.linux_master[*].public_ip
}

output "linux_worker_public_ips" {
  value = aws_instance.linux_worker[*].public_ip
}

# output "cluster_id" {
#   value = rancher2_cluster_v2.rke2_win_cluster.id
# }




### OUTPUT 

output "rancher2_local_cluster_node_ips" {
  value =  [module.rancherv2.rancher2_local_cluster_node_ips]
}

output "rancher2_url" {
  value =  module.rancherv2.rancher2_url
}

output "rancher2_admin_user" {
  value =  module.rancherv2.rancher2_admin_user
}

output "rancher2_token" {
  value =  module.rancherv2.rancher2_token
  sensitive = true
}

output "k3s_token" {
  value = module.rancherv2.k3s_token
  sensitive = true
}

output "k3s_agent_token" {
  value = module.rancherv2.k3s_agent_token
  sensitive = true
}


output "rancher2_password" {
  value =  module.rancherv2.rancher2_password
  sensitive = true
}

output "downstream_cluster" {
  value =  module.rancherv2.downstream_cluster

}

output "insecure_rke2_cluster_command" {
  value =  module.rancherv2.insecure_rke2_cluster_command
  sensitive = true
}

output "insecure_rke2_cluster_windows_command" {
  value =  module.rancherv2.insecure_rke2_cluster_windows_command
  sensitive = true
}

output "secure_rke2_cluster_command" {
  value =  module.rancherv2.secure_rke2_cluster_command
  sensitive = true
}

output "secure_rke2_cluster_windows_command" {
  value =  module.rancherv2.secure_rke2_cluster_windows_command
  sensitive = true
}