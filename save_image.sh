#!/bin/bash

# Authenticate to GCloud
gcloud auth configure-docker

# Build and tag the image
docker build -t adam_demo-crm:latest .
docker tag adam_demo-crm:latest gcr.io/kubernetes-bootcamp-365905/adam_demo-crm:latest

# Push the image to GCR repository
docker push gcr.io/kubernetes-bootcamp-365905/adam_demo-crm:latest
echo -e "The docker image has been build, tagged, and pushed successfully."

