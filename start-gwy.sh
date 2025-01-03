#!/bin/bash
# Usage: start.sh
# Description:  Builds a 3-worker k8s cluster in Kind with GlooGateway providing ingress.  

echo -e "\n*** Deploy Cloud Provider Kind ***"
docker run -d --rm --name cloud-provider-kind --network kind \
-v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.4.0

echo -e "\n*** Deploy Kind Cluster ***"
kind create cluster --config=$PWD/kind/config.yaml --name demo-kind-cluster

if [ -z "$(docker image ls -q ms1:1.0)" ]
then
    echo -e "\n*** Build Microservice 1 Container ***"
    docker build --no-cache --tag ms1:1.0 $PWD/ms1
fi

if [ -z "$(docker image ls -q ms2:1.0)" ]
then
    echo -e "\n*** Build Microservice 2 Container ***"
    docker build --no-cache --tag ms2:1.0 $PWD/ms2
fi

echo -e "\n*** Load Microservice Images ***"
kind --name demo-kind-cluster load docker-image ms1:1.0
kind --name demo-kind-cluster load docker-image ms2:1.0

echo -e "\n*** Deploy Microservices ***"
kubectl apply -f $PWD/ms1/ms1-deployment.yaml
kubectl apply -f $PWD/ms2/ms2-deployment.yaml
kubectl rollout status deployment/ms1-app
kubectl rollout status deployment/ms2-app

echo -e "\n*** Deploy K8s Gateway API ***"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

if ! helm repo list | grep -q "gloo"; then
    echo -e "\n*** Add Gloo Gateway ***"
    helm repo add gloo https://storage.googleapis.com/solo-public-helm
    helm repo update
fi

echo -e "\n*** Deploy Gloo Gateway ***"
helm install -n gloo-system gloo gloo/gloo \
--create-namespace \
-f- <<EOF
discovery:
  enabled: false
gatewayProxies:
  gatewayProxy:
    disabled: true
gloo:
  disableLeaderElection: true
kubeGateway:
  enabled: true
EOF

kubectl apply -n gloo-system -f- <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: http
spec:
  gatewayClassName: gloo-gateway
  listeners:
  - protocol: HTTP
    port: 8080
    name: http
    allowedRoutes:
      namespaces:
        from: All
EOF

echo -e "\n*** Create Routes to Microservices ***"
kubectl apply -f $PWD/ms1/ms1-route.yaml
kubectl apply -f $PWD/ms2/ms2-route.yaml
sleep 5

echo -e "\n*** Deployment Complete ***"
INGRESS_GW_ADDRESS=$(kubectl get svc -n gloo-system gloo-proxy-http -o=jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo "Gateway Address: "$INGRESS_GW_ADDRESS

curl --retry 10 --retry-all-errors --retry-delay 2 -f -s -o /dev/null http://$INGRESS_GW_ADDRESS:8080/service1
echo -e "\n*** MS1 Service ***"
curl -w "\n" http://$INGRESS_GW_ADDRESS:8080/service1

echo -e "\n*** MS2 Service ***"
curl -w "\n" http://$INGRESS_GW_ADDRESS:8080/service2
