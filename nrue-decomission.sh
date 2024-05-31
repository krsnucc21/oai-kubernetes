#!/bin/bash

kubectl delete -f nrue-deployment.yaml
kubectl delete configmap nrue-config

kubectl get pods -o wide
