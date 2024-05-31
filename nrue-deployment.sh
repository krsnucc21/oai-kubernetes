#!/bin/bash

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

kubectl create configmap nrue-config --from-file=nr-ue.conf=./nrue.uicc.conf
kubectl apply -f nrue-deployment.yaml

# Wait for nrue pod to be ready and display logs
nrue_pod=$(get_pod_name "oai-nr-ue")

if [ -n "$nrue_pod" ]; then
  wait_for_pod "$nrue_pod"
  display_logs "$nrue_pod" | tail
else
  echo "nrue pod pod with prefix 'oai-nr-ue' not found."
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

sleep 10

kubectl exec -it "$nrue_pod" -- ping -I oaitun_ue1 -s 60000 12.1.1.1
