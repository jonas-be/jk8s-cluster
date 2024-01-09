#!/bin/bash

helm repo add rook-release https://charts.rook.io/release
helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph -f values.yaml

# After ceph cluster is ready do:
# kubectl apply -f cluster.yaml
