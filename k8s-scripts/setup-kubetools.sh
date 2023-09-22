#!/bin/bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

if test ! -f /etc/apt/sources.list.d/kubernetes.list; then

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

fi
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo swapoff -a
	
sudo sed -i 's/\/swap/#\/swap/' /etc/fstab

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock