#!/bin/bash

# Close and re-initate the Google Cloud cluster if applicable.
printf "y\n" | gcloud container clusters delete argo-cd || true
gcloud container clusters create argo-cd  || true

# Install the Cert Manager first
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true
sleep 5

# Next upgrade Ingress Nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
sleep 5

# Update and install the demo CRM helm chart
helm package adam-demo-crm
mv adam-demo-crm-0.1.1.tgz adam-helm-repo
helm install adam-helm-repo adam-demo-crm --wait

#Apply the certificate
sleep 5
kubectl apply -f cert-issuer-nginx-ingress.yaml
sleep 2
kubectl apply -f certificate.yaml

sleep 2
PUBLIC_IP=$(kubectl get svc --namespace=ingress-nginx ingress-nginx-controller -ojsonpath='{.status.loadBalancer.ingress[].ip}{"\n"}')

echo -e "Copy and paste the public IP of the app - ${PUBLIC_IP} - in the DNS provider's config and try to curl the page:"
echo -e "curl -I https://adam-demo.ddns.net"