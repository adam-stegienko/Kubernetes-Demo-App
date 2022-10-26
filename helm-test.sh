#!/bin/bash

helm package adam-demo-crm
mv adam-demo-crm-0.1.1.tgz adam-helm-repo
helm install adam-helm-repo adam-demo-crm --wait || exit 0