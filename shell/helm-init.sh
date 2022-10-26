#!/bin/bash

# Close and re-initate the Google Cloud cluster if applicable.
# printf "y\n" | gcloud container clusters delete adam-cluster || true
# gcloud container clusters create adam-cluster || true

# Install MongoDB
helm install mongodb --values mongo-custom-values.yaml bitnami/mongodb
sleep 200

# Source new values given during the installation
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
RABBITMQ_PASSWORD=$(kubectl get secret --namespace default rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)
MONGODB_ROOT_USER="root"

# Update secret env with new values
sed -i '/MONGODB_URI/d' ./adam-demo-crm/templates/secret.yaml || true
sed -i '/RABBITMQ_URI/d' ./adam-demo-crm/templates/secret.yaml || true
sed -i '/MONGODB_ROOT_USER/d' ./adam-demo-crm/templates/secret.yaml || true
sed -i '/MONGODB_ROOT_PASSWORD/d' ./adam-demo-crm/templates/secret.yaml || true

MONGODB_USR=$(echo -n "${MONGODB_ROOT_USER}" | base64)
MONGODB_PWD=$(echo -n "${MONGODB_ROOT_PASSWORD}" | base64)
MONGODB_ENCODED=$(echo -n "mongodb://root:${MONGODB_ROOT_PASSWORD}@mongodb-0.mongodb-headless:27017" | base64)
MONGODB_TRIMMED=$(echo "$MONGODB_ENCODED" | sed 'N;s/\n/ /'| tr -d " ")
RABBITMQ_ENCODED=$(echo -n "amqp://user:${RABBITMQ_PASSWORD}@rabbitmq-0.rabbitmq-headless:5672" | base64)
RABBITMQ_TRIMMED=$(echo "$RABBITMQ_ENCODED" | sed 'N;s/\n/ /'| tr -d " ")

echo -e "\n  MONGODB_ROOT_USER: ${MONGODB_USR}" >> ./adam-demo-crm/templates/secret.yaml
echo -e "\n  MONGODB_ROOT_PASSWORD: ${MONGODB_PWD}" >> ./adam-demo-crm/templates/secret.yaml
echo -e "\n  MONGODB_URI: $MONGODB_TRIMMED" >> ./adam-demo-crm/templates/secret.yaml
echo -e "\n  RABBITMQ_URI: $RABBITMQ_TRIMMED" >> ./adam-demo-crm/templates/secret.yaml

sed -i '/^$/d' ./adam-demo-crm/templates/secret.yaml || true
sleep 3

#Updating helm chart's secret file with new values
helm package adam-demo-crm
mv adam-demo-crm-0.1.1.tgz adam-helm-repo
helm install adam-helm-repo adam-demo-crm
# helm upgrade -f certificate.yaml ingress.yaml cert-issuer-nginx-ingress.yaml service.yaml deployment.yaml cronjob.yaml secret.yaml adam-helm-repo adam-demo-crm
sleep 5

# Final message
PUBLIC_IP=$(kubectl get svc --namespace=ingress-nginx ingress-nginx-controller -ojsonpath='{.status.loadBalancer.ingress[].ip}{"\n"}')

echo -e "Copy and paste the public IP of the app - ${PUBLIC_IP} - in the DNS provider's config and try to curl the page:"
echo -e "curl -I https://adam-demo.ddns.net"