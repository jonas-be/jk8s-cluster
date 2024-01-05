#!/bin/bash

helm repo add traefik https://traefik.github.io/charts
helm repo update

kubectl create namespace traefik
helm install --namespace=traefik --values values.yaml traefik traefik/traefik
