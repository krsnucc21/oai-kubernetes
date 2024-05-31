#!/bin/bash

kubectl delete -f ext-dn-deployment.yaml

kubectl delete -f smf-deployment.yaml
kubectl delete configmap smf-config

kubectl delete -f upf-deployment.yaml
kubectl delete configmap upf-config

kubectl delete -f amf-deployment.yaml
kubectl delete configmap amf-config

kubectl delete -f mysql-deployment.yaml
kubectl delete configmap mysql-config

kubectl delete -f network-attachment.yaml

echo "kubectl get network-attachment-definitions"
kubectl get network-attachment-definitions
echo "kubectl get configmaps"
kubectl get configmaps
echo "kubectl get pods"
kubectl get pods
