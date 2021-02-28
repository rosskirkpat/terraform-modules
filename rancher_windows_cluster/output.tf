output "linux_all_public_ips" {
  value = aws_instance.linux_all[*].public_ip
}
output "linux_controlplane_public_ips" {
  value = aws_instance.linux_cp[*].public_ip
}
output "linux_etcd_public_ips" {
  value = aws_instance.linux_etcd[*].public_ip
}
output "linux_worker_public_ips" {
  value = aws_instance.linux_worker[*].public_ip
}
output "windows_worker_public_ips" {
  value = aws_instance.windows_worker[*].public_ip
}
output "windows_passwords" {
  value = data.template_file.decrypted_keys.*.rendered
}