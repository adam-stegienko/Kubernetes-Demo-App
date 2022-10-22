# Demo CRM Adam Project

## Instruction on how to run it

#### 1. Run MongoDB from Helm Chart (with customer values file)

'''
helm install mongodb --values mongodb/mongo-custom-values.yaml bitnami/mongodb
'''

#### 2. Run RabbitMQ from Helm Chart

'''
helm install rabbitmq bitnami/rabbitmq
'''

#### 3. Save the credentials from RabbitMQ

#### 4. Create and save your API key from https://newsapi.org

#### 5. Create a secret file with base64-encoded values taken from .env.local file

'''
kubectl apply -f secret-env.yaml
'''

#### 6. Apply the secret values into Demo CRM and News Getter apps' deployment files

#### 7. Run Demo CRM and News Getter from K8s CLI

'''
kubectl apply -f ./demo-crm
kubectl apply -f ./news-getter
'''

