#!/bin/bash

# Close and re-initate the Google Cloud cluster if applicable.
printf "y\n" | gcloud container clusters delete argo-cd || true
gcloud container clusters create argo-cd  || true

# Install MongoDB
helm install mongodb --values mongo-custom-values.yaml bitnami/mongodb
sleep 150

# Install RabbitMQ
helm install rabbitmq bitnami/rabbitmq
sleep 10

# Source new values given during the installation
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
RABBITMQ_PASSWORD=$(kubectl get secret --namespace default rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d)
MONGODB_ROOT_USER="root"

# Update config map with new values
sed -i '/MONGODB_URI/d' config-map.yaml || true
sed -i '/RABBITMQ_URI/d' config-map.yaml || true
sed -i '/MONGODB_ROOT_USER/d' config-map.yaml || true
sed -i '/MONGODB_ROOT_PASSWORD/d' config-map.yaml || true

echo -e "\n" >> config-map.yaml
echo -e "\n  MONGODB_ROOT_USER: ${MONGODB_ROOT_USER}" >> config-map.yaml
echo -e "\n  MONGODB_ROOT_PASSWORD: ${MONGODB_ROOT_PASSWORD}" >> config-map.yaml
echo -e "\n  MONGODB_URI: mongodb://root:${MONGODB_ROOT_PASSWORD}@mongodb-0.mongodb-headless:27017" >> config-map.yaml
echo -e "\n  RABBITMQ_URI: amqp://user:${RABBITMQ_PASSWORD}@rabbitmq-0.rabbitmq-headless:5672" >> config-map.yaml

sed -i '/^$/d' config-map.yaml || true
sleep 10

# Update secret env with new values
sed -i '/MONGODB_URI/d' secret-env.yaml || true
sed -i '/RABBITMQ_URI/d' secret-env.yaml || true
sed -i '/MONGODB_ROOT_USER/d' secret-env.yaml || true
sed -i '/MONGODB_ROOT_PASSWORD/d' secret-env.yaml || true

MONGODB_USR=$(echo -n "${MONGODB_ROOT_USER}" | base64)
MONGODB_PWD=$(echo -n "${MONGODB_ROOT_PASSWORD}" | base64)
MONGODB_ENCODED=$(echo -n "mongodb://root:${MONGODB_ROOT_PASSWORD}@mongodb-0.mongodb-headless:27017" | base64)
MONGODB_TRIMMED=$(echo "$MONGODB_ENCODED" | sed 'N;s/\n/ /'| tr -d " ")
RABBITMQ_ENCODED=$(echo -n "amqp://user:${RABBITMQ_PASSWORD}@rabbitmq-0.rabbitmq-headless:5672" | base64)
RABBITMQ_TRIMMED=$(echo "$RABBITMQ_ENCODED" | sed 'N;s/\n/ /'| tr -d " ")

echo -e "\n  MONGODB_ROOT_USER: ${MONGODB_USR}" >> secret-env.yaml
echo -e "\n  MONGODB_ROOT_PASSWORD: ${MONGODB_PWD}" >> secret-env.yaml
echo -e "\n  MONGODB_URI: $MONGODB_TRIMMED" >> secret-env.yaml
echo -e "\n  RABBITMQ_URI: $RABBITMQ_TRIMMED" >> secret-env.yaml

sed -i '/^$/d' secret-env.yaml || true
sleep 10
 
kubectl apply -f config-map.yaml
sleep 2
kubectl apply -f secret-env.yaml
sleep 2
kubectl apply -f demo-crm-deployment.yaml
sleep 2
kubectl apply -f demo-crm-service.yaml
sleep 2
kubectl apply -f news-getter-deployment.yaml
sleep 2

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

sleep 5
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true

sleep 5
kubectl apply -f demo-crm-ingress.yaml
sleep 2

kubectl apply -f cert-issuer-nginx-ingress.yaml
sleep 2

kubectl apply -f certificate.yaml
sleep 2

kubectl apply -f demo-crm-ingress.yaml
sleep 2

PUBLIC_IP=$(kubectl get svc --namespace=ingress-nginx ingress-nginx-controller -ojsonpath='{.status.loadBalancer.ingress[].ip}{"\n"}')

echo -e "Copy and paste the public IP of the app - ${PUBLIC_IP} - in the DNS provider's config and try to curl the page:"
echo -e "curl -I https://adam-demo.ddns.net"
sleep 30
kubectl apply -f demo-crm-cronjob.yaml
sleep 2

# # ArgoCD installed in cluster
# kubectl create namespace argocd || true
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# sleep 2

# # ArgoCD CLI added
# sudo install -m 555 argocd-darwin-amd64 /usr/local/bin/argocd || true
# rm argocd-darwin-amd64 || true

# # Ingress configuration to be performed here
# # For the temporary use, the port forwarding approach will be used
#   # kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# # Logging in
# export ARGO_INIT_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# export ARGOCD_OPTS='--port-forward-namespace argocd'

# argocd login argocd-server

# # After logging in, the init password should be updated using the following command:
#   # argocd account update-password