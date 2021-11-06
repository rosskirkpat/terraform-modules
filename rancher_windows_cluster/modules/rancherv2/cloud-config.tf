data "template_file" "cloud-config" {
  template = <<YAML
#cloud-config

locale: "en_US.UTF-8"
timezone: "America/New_York"

package_update: true

packages:
  - nano
  - net-tools
  - bash
  - jq

users:
  - default
  - name: rancher
    gecos: rancher
    primary_group: rancher    
    sudo: ALL=(ALL) NOPASSWD:ALL    
    groups: users, admin
    lock_passwd: false    
    ssh_authorized_keys:
      - "${tls_private_key.rancher_ssh_key.public_key_openssh}"

write_files:
  - path: /run/setup-environment.sh
    permissions: '0755'
    content: |
      #!/bin/bash

      ENV="/etc/environment"

      # Test for RW access to $1
      touch $ENV
      if [ $? -ne 0 ]; then
          echo exiting, unable to modify: $ENV
          exit 1
      fi

      # clean environment file
      sed -i -e '/^PUBLIC_IPV4/d' \
          -e '/^LOCAL_IPV4/d' \
          "$ENV"

      function get_local_ip () {
        while [ 1 ]; do
          _out=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
          if [ -z "$_out" ]; then
            sleep 1
          else
            echo $_out
            exit
          fi
        done
      }

      function get_public_ip () {
        while [ 1 ]; do
          _out=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
          if [ -z "$_out" ]; then
            sleep 1
          else
            echo $_out
            exit
          fi
        done
      }

      # Echo results of IP queries to environment file
      echo getting private ipv4 from AWS instance metadata...
      echo PUBLIC_IPV4=$(get_public_ip) >> $ENV
      echo getting public ipv4 from AWS instance metadata...
      echo LOCAL_IPV4=$(get_local_ip) >> $ENV

  - path: /etc/environment
    append: true
    content: |
      PUBLIC_IPV4=$(cloud-init query ds.meta_data.public_ipv4)
      LOCAL_IPV4=$(cloud-init query ds.meta_data.local_ipv4)

  - path: /run/set-k3s-config.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      cat <<'EOF' | sed -e "s/PUBLIC/"$PUBLIC_IPV4"/g" -e "s/LOCAL/"$LOCAL_IPV4"/g" > /etc/rancher/k3s/config.yaml
      write-kubeconfig-mode: "0644"
      node-ip: "LOCAL"
      tls-san:
        - "PUBLIC.nip.io"
        - "PUBLIC"
      token: "${random_password.k3s_token.result}"
      agent-token:"${random_password.k3s_agent_token.result}"
      disable-cloud-controller: true
      EOF

runcmd:
  - [ sh, -c "/run/setup-environment.sh" ]
  - [ sh, -c "/run/set-k3s-config.sh" ]
  - [ sh, -c, "sudo systemctl disable --now firewalld" ]
  - curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${var.rancher_kubernetes_version}" sh -
  - echo 'This instance was provisioned by Terraform.' >> /etc/motd
  
final_message: "The system is finally up, after $UPTIME seconds"
YAML
}