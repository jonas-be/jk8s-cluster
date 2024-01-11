#!/bin/bash

# Required environment variables
env_vars=("NEW_USER" "PW" "NEW_HOSTNAME")

# Check if required environment variables are set
for var in "${env_vars[@]}"; do
  if [ "${!var}" == "" ]; then
    printf "\e[0;31mError: Environment variable \e[1m$var\e[0;31m is empty.\e[0m\n"
    exit 1
  fi
done


hostnamectl set-hostname $NEW_HOSTNAME

# Create new user
useradd -m -s /bin/bash $NEW_USER
usermod -aG sudo $NEW_USER
echo "$NEW_USER:$PW" | sudo chpasswd

# Copy ssh keys to the new user and remove ssh keys from root
cp -r .ssh /home/$NEW_USER
chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
chown &NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
rm .ssh/authorized_keys

# Upgrade system
apt update
apt upgrade -y

# Install containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay 
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1 
net.bridge.bridge-nf-call-ip6tables = 1 
EOF

sudo sysctl --system

sudo apt update
sudo apt -y install containerd

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Install kubelet, kubeadm, kubectl
apt install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
