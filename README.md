# GlooGateway on Kind Demo

## Contents
1.  [Summary](#summary)
2.  [Architecture](#architecture)
3.  [Approach](#approach)
4.  [Prerequisites](#prerequisites)
5.  [Usage](#usage)

## Summary <a name="summary"></a>
This demonstrates integration of the solo.io GlooGateway on a Kind k8s cluster.  

## Architecture <a name="architecture"></a>


## Approach <a name="approach"></a>
- Cloud Provider Kind is deployed as Docker contain to provide LoadBalance services
- A 3-worker node Kind cluster is deployed
- GlooGateway (OSS) is deployed
- 2 simplistic Nodejs microservices are deployed with 3 replicas per
- GlooGateway routes are created to the 2 Nodejs service endpoints

## Prerequisites <a name="prerequisites"></a>
- Docker
- Kind

## Usage <a name="usage"></a>
### Start up
```bash
./start.sh
```
### Shutdown
```bash
./stop.sh
```