#/bin/bash
docker stop cloud-provider-kind
kind delete cluster --name demo-kind-cluster