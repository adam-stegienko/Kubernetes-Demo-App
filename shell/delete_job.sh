#!/bin/bash

USER="root"
export PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)

kubectl exec -it mongodb-0 -- /bin/bash << EOF
mongosh -u $USER -p $PASSWORD
db.clients.find ( {} )
db.clients.deleteMany ( {} )
EOF