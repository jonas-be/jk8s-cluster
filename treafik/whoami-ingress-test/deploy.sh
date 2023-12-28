#!/bin/bash
kubectl apply -f whoami.yaml \
	-f whoami-services.yaml \
	-f whoami-ingress.yaml
