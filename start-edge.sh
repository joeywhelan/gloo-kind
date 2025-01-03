#!/bin/bash
# Usage: start.sh
# Description:  Builds a 3-worker k8s cluster in Kind with GlooGateway providing ingress.  

if [ ! -f glooctl ]
then
    echo -e "\n*** Download Glooctl ***"
    curl -sL https://run.solo.io/gloo/install | sh
    mv $HOME/.gloo/bin/glooctl .
    chmod +x glooctl
    rm -rf $HOME/.gloo
fi

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


echo -e "\n*** Deploy Gloo Gateway ***"
./glooctl install gateway

echo -e "\n*** Create Routes to Microservices ***"
./glooctl  add route --name vs1 --path-exact /ms1 --dest-name default-ms1-service-8000 --prefix-rewrite /service1
./glooctl  add route --name vs1 --path-exact /ms2 --dest-name default-ms2-service-9000 --prefix-rewrite /service2

echo -e "\n*** Deployment Complete ***"
GLOO_PROXY_URL=$(./glooctl proxy url --name gateway-proxy)  
echo "Gloo Proxy URL: "$GLOO_PROXY_URL

curl --retry 10 --retry-all-errors --retry-delay 2 -f -s -o /dev/null $GLOO_PROXY_URL/ms1
echo -e "\n*** MS1 Service ***"
curl -w "\n" $GLOO_PROXY_URL/ms1
echo -e "\n*** MS2 Service ***"
curl -w "\n" $GLOO_PROXY_URL/ms2