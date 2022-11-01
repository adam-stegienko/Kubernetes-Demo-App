# Kubernetes Demo App

#### IMPORTANT CHANGE

Now in the new version of the app you can run the whole app from the scratch using just one command:

`./app-init.sh`

App should be accessed on the website: https://adam-demo.ddns.net/


## Instruction on how to run it

#### 1. Run MongoDB from Helm Chart (with customer values file)

`helm install mongodb --values mongo-custom-values.yaml bitnami/mongodb`

Obtain and encode the provided random root password:
```
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
echo $MONGODB_ROOT_PASSWORD
```
Paste this value into the config map and then encode again. Paste it to the secret-env.yaml file to replace the old values.

#### 2. Run RabbitMQ from Helm Chart

`helm install rabbitmq bitnami/rabbitmq`

#### 3. Save the credentials from RabbitMQ and replace the in secret-env.yaml file.

#### 4. Create and save your API key from https://newsapi.org

#### 5. Create a secret file with base64-encoded values taken from .env.local file

`kubectl apply -f config-map.yaml`
`kubectl apply -f secret-env.yaml`

#### 6. Apply the secret values into Demo CRM and News Getter apps' deployment files

#### 7. Run Demo CRM and News Getter from K8s CLI

`kubectl apply -f demo-crm-deployment.yaml`
`kubectl apply -f demo-crm-service.yaml`
`kubectl apply -f news-getter-deployment.yaml`

#### 8. Run Nginx Ingress Controller from Helm Chart

```
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

#### 9. HTTPS -> TLS Cert Manager

Create a new namespace for Cert Manager.
`kubectl create ns cert-manager`

Install Cert Manager.
`kubectl apply --validate=false -f cert-manager-1.10.0.yaml`

Apply the app's ingress.
`kubectl apply -f demo-crm-ingress.yaml`

Install Cert Issuer for Nginx Ingress.
`kubectl apply -f cert-issuer-nginx-ingress.yaml`

Create a TLS certificate.
`kubectl apply -f certificate.yaml`

#### 10. Run command to obtain the ingress's public IP address and attach it to your DNS host name.

`kubectl get svc --namespace=ingress-nginx ingress-nginx-controller -ojsonpath='{.status.loadBalancer.ingress[].ip}{"\n"}'`

