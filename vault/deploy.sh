#!/bin/bash

helm repo add hashicorp https://helm.releases.hashicorp.com

helm install vault hashicorp/vault --create-namespace --namespace vault


helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
