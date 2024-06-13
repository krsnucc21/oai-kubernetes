#!/bin/bash

kubectl describe configmap cu-config | grep OAI-CU
kubectl describe configmap du-config | grep OAI-DU
kubectl describe configmap oai-ip-config

kubectl delete -f du-deployment.yaml
kubectl delete -f cu-deployment.yaml

kubectl delete configmap cu-config
kubectl delete configmap du-config
kubectl delete -f ip-config.yaml

kubectl delete -f configmap-rolebinding.yaml
kubectl delete -f configmap-role.yaml
kubectl delete -f configmap-serviceaccount.yaml

echo "kubectl get network-attachment-definitions"
kubectl get network-attachment-definitions
echo "kubectl get configmaps"
kubectl get configmaps
echo "kubectl get pods"
kubectl get pods
