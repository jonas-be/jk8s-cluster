#!/bin/bash
kubectl apply -f role.yaml \
	-f account.yaml \
	-f role-binding.yaml \
	-f traefik.yaml \
	-f traefik-services.yaml
