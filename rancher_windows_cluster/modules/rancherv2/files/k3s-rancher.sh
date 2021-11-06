#!/bin/sh
# setup k3s server and install rancher
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
systemctl disable --now firewalld
export INSTALL_K3S_VERSION="v1.21.5+k3s2"


  - \curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_version} K3S_KUBECONFIG_MODE=0644 INSTALL_K3S_EXEC="server --node-external-ip $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) --node-ip $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --tls-san $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4).nip.io" sh -s -


curl -sfL https://get.k3s.io | sh -
mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/config.yaml <<EOF
write-kubeconfig-mode: "0644"
tls-san:
  - "${PUBLIC_IP}" 
  - "${PUBLIC_IP}.nip.io"
cni: "calico"
node-external-ip: "${PUBLIC_IP}"
node-ip:
token: 
EOF

systemctl enable rke2-server
systemctl start rke2-server

sed "s/127.0.0.1/$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/g" /etc/rancher/k3s/k3s.yaml


cat >> /etc/profile <<EOF
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yaml
PATH="$PATH:/var/lib/rancher/k3s/bin"
alias k=kubectl
EOF

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yaml
PATH="$PATH:/var/lib/rancher/k3s/bin"

mkdir -p /var/lib/rancher/k3s/server/manifests
cat >> /var/lib/rancher/k3s/server/manifests/k3s-ingress-nginx-config.yaml <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: k3s-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      kind: DaemonSet
      daemonset:
        useHostPort: true
EOF

# wget -q -P /var/lib/rancher/k3s/server/manifests/ https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml

cat > /var/lib/rancher/k3s/server/manifests/rancher.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cattle-system
---
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    certmanager.k8s.io/disable-validation: "true"
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  targetNamespace: cert-manager
  repo: https://charts.jetstack.io
  chart: cert-manager
  version: v1.5.1
  helmVersion: v3
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rancher
  namespace: kube-system
spec:
  targetNamespace: cattle-system
  repo: https://releases.rancher.com/server-charts/stable/
  chart: rancher
  set:
    hostname: ${PUBLIC_IP}.nip.io
    replicas: 1
    rancherImageTag: v2.6.2
    antiAffinity: required
    bootstrapPassword: admin123!
  helmVersion: v3
EOF