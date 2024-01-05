#!/bin/bash

cat <<EOF | sudo tee kubeadm-conf.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
controlPlaneEndpoint: cp.k8s.jonasbe.de:6443
clusterName: "jk8s-cluster"
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

kubeadm init --config kubeadm-conf.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
