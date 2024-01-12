#!/bin/bash

# Required environment variables
env_vars=("CP_ENDPOINT" "CLUSTER_NAME")

# Check if required environment variables are set
for var in "${env_vars[@]}"; do
  if [ "${!var}" == "" ]; then
    printf "\e[0;31mError: Environment variable \e[1m$var\e[0;31m is empty.\e[0m\n"
    exit 1
  fi
done


# Get root rights with sudo
# If PW is not set, ask for it
echo $PW | sudo -S whoami


cat <<EOF | sudo tee kubeadm-conf.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
controlPlaneEndpoint: $CP_ENDPOINT
clusterName: $CLUSTER_NAME
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
---
kind: InitConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
EOF

sudo kubeadm init --config kubeadm-conf.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
