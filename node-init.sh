#!/bin/bash

hostnamectl set-hostname nc1.jonasbe.de

# Create user jonasbe
useradd -m -s /bin/bash jonasbe
usermod -aG sudo jonasbe

# Copy ssh keys to jonasbe and remove ssh keys from root
cp -r .ssh /home/jonasbe
chown jonasbe:jonasbe /home/jonasbe/.ssh
chown jonasbe:jonasbe /home/jonasbe/.ssh/authorized_keys
rm .ssh/authorized_keys

# Upgrade system
apt update
apt upgrade -y

# Install containerd
echo "Comming soon"

# Install kubelet, kubeadm, kubectl
apt install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
