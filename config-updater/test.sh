#!/bin/bash

kubectl create configmap cu-config --from-file=gnb.conf=../gnb-cu.sa.band78.106prb.conf
kubectl describe configmap cu-config | grep OAI-CU
kubectl create configmap du-config --from-file=gnb.conf=../gnb-du.sa.band78.106prb.rfsim.conf
kubectl describe configmap du-config | grep OAI-DU
kubectl apply -f ../ip-config.yaml
kubectl describe configmap oai-ip-config
kubectl apply -f config-updater-du.yaml
kubectl get pods -o wide
kubectl describe configmap oai-ip-config
kubectl apply -f config-updater-cu.yaml
kubectl get pods -o wide
kubectl describe configmap oai-ip-config

# Function to get the full pod name by prefix
get_pod_name() {
  local pod_prefix=$1
  kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep ^$pod_prefix
}

# Function to display the logs of a pod
display_logs() {
  local pod_name=$1
  echo "Displaying logs for pod: $pod_name"
  kubectl logs $pod_name
}

# Main script
echo "Fetching logs for CU and DU pods..."

# Get the pod names
cu_pod=$(get_pod_name "oai-ip-cu")
du_pod=$(get_pod_name "oai-ip-du")

# Wait for 10 seconds
echo "Waiting for 10 seconds..."
sleep 10

# Display logs for CU pod
if [ -n "$cu_pod" ]; then
  display_logs "$cu_pod"
else
  echo "CU pod with prefix 'oai-ip-cu' not found."
fi

# Display logs for DU pod
if [ -n "$du_pod" ]; then
  display_logs "$du_pod"
else
  echo "DU pod with prefix 'oai-ip-du' not found."
fi

kubectl describe configmap cu-config | grep OAI-CU
kubectl describe configmap du-config | grep OAI-DU
kubectl describe configmap oai-ip-config

kubectl get pods -o wide

kubectl delete -f config-updater-du.yaml
kubectl delete -f config-updater-cu.yaml

kubectl delete configmap cu-config
kubectl delete configmap du-config
kubectl delete -f ../ip-config.yaml
