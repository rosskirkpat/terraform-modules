# K3s cluster for Rancher

# resource "sshcommand_command" "install_k3s" {
#   count       = aws_instance.rancher_master.count
#   host        = aws_instance.rancher_master[0]
#   command     = "bash -c 'curl https://get.k3s.io | INSTALL_K3S_EXEC=\"server --node-external-ip ${data.aws_instance.rancher_master.public_ip} --node-ip ${data.aws_instance.rancher_master.private_ip}\" INSTALL_K3S_VERSION=${var.rancher_kubernetes_version} sh -'"
#   user        = "ec2-user"
#   private_key = tls_private_key.ssh_key.private_key_pem
# }



resource "sshcommand_command" "retrieve_config" {
  depends_on = [
    aws_instance.rancher_master,
    # local_file.rancher_pem_file
    ]
  #  count      = length(aws_instance.rancher_master)
  #  host          = aws_instance.rancher_master[0].public_ip
  host           = aws_instance.rancher_master[0].public_ip
  command        = "sudo sed s/127.0.0.1/$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/g /etc/rancher/k3s/k3s.yaml"
  # command        = "sudo cat /etc/rancher/k3s/k3s.yaml"
  user           = "ec2-user"
  # private_key = tls_private_key.rancher_ssh_key.private_key_pem
  private_key    = local_file.rancher_pem_file.sensitive_content
  retry          = true
  retry_interval = "10s"
  retry_timeout  = "120s"
}

output "kubeconfig" {
  value = sshcommand_command.retrieve_config.result
}
