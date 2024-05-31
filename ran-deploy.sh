#!/bin/bash

kubectl create configmap cu-config --from-file=gnb.conf=./gnb-cu.sa.band78.106prb.conf
kubectl describe configmap cu-config | grep OAI-CU
kubectl create configmap du-config --from-file=gnb.conf=./gnb-du.sa.band78.106prb.rfsim.conf
kubectl describe configmap du-config | grep OAI-DU
kubectl apply -f ip-config.yaml
kubectl describe configmap oai-ip-config
kubectl apply -f cu-deployment.yaml
kubectl get pods -o wide
kubectl describe configmap oai-ip-config
kubectl apply -f du-deployment.yaml
kubectl get pods -o wide
kubectl describe configmap oai-ip-config

# Function to get the full pod name by prefix
get_pod_name() {
  local pod_prefix=$1
  kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep ^$pod_prefix
}

# Function to check if a pod is ready
is_pod_ready() {
  local pod_name=$1
  kubectl get pod $pod_name -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep True
}

# Function to wait for a pod to be ready
wait_for_pod() {
  local pod_name=$1
  echo "Waiting for pod $pod_name to be ready..."
  while true; do
    if is_pod_ready $pod_name; then
      echo "Pod $pod_name is ready."
      break
    fi
    sleep 5
  done
}

# Function to display the logs of a pod
display_logs() {
  local pod_name=$1
  echo "Displaying logs for pod: $pod_name"
  kubectl logs $pod_name | tail
}

# Main script
echo "Fetching logs for CU and DU pods..."

# Get the pod names
cu_pod=$(get_pod_name "oai-cu")
du_pod=$(get_pod_name "oai-du")

# Wait for CU pod to be ready and display logs
if [ -n "$cu_pod" ]; then
  wait_for_pod "$cu_pod"
  display_logs "$cu_pod" | tail
else
  echo "CU pod with prefix 'oai-cu' not found."
fi

# Wait for DU pod to be ready and display logs
if [ -n "$du_pod" ]; then
  wait_for_pod "$du_pod"
  display_logs "$du_pod" | tail
else
  echo "DU pod with prefix 'oai-du' not found."
fi

# Wait for amf pod to be ready and display logs
amf_pod=$(get_pod_name "oai-amf")

if [ -n "$amf_pod" ]; then
  wait_for_pod "$amf_pod"
  display_logs "$amf_pod" | tail
else
  echo "amf pod with prefix 'oai-amf' not found."
fi

kubectl get pods -o wide
