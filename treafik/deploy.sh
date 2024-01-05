#!/bin/bash

# Treafik
helm repo add traefik https://traefik.github.io/charts
helm repo update

kubectl create namespace traefik
helm install --namespace=traefik --values values.yaml traefik traefik/traefik


# Cert Manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.3/cert-manager.yaml


# Cluster Issuer
kubectl apply -f letsencrypt-issuer.yaml
