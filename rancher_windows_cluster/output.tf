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
