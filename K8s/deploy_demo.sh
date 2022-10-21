#!/bin/bash

# Authenticate to GCloud
gcloud auth configure-docker

# Pulling the docker image from GCR registry
docker pull gcr.io/kubernetes-bootcamp-365905/adam_demo-crm:latest
echo -e "Image pulled from repo successfully."

# Deploy everything in K8s
kubectl apply -f .