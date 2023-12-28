#!/bin/bash

cat <<EOF | sudo tee kubeadm-conf.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
controlPlaneEndpoint: jonasbe.de:6443
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

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
