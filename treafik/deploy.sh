#!/bin/bash

helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik

helm install --namespace=traefik --values values.yaml traefik traefik/traefik
