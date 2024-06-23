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

kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
kubectl get daemonsets.apps -n kube-system

kubectl apply -f network-attachment.yaml
kubectl describe network-attachment-definitions

kubectl create configmap mysql-config --from-file=./oai_db.sql --from-file=./mysql-healthcheck.sh
kubectl apply -f mysql-deployment.yaml

kubectl create configmap amf-config --from-file=mini_nonrf_config_3slices.yaml=./mini_nonrf_config_3slices.yaml
kubectl apply -f amf-deployment.yaml

kubectl get pods -o wide

mysql_pod=$(get_pod_name "mysql")
amf_pod=$(get_pod_name "oai-amf")

if [ -n "$mysql_pod" ]; then
  wait_for_pod "$mysql_pod"
else
  echo "mysql pod with prefix 'mysql' not found."
fi

if [ -n "$amf_pod" ]; then
  wait_for_pod "$amf_pod"
else
  echo "amf pod with prefix 'oai-amf' not found."
fi

kubectl create configmap upf-config --from-file=mini_nonrf_config_3slices.yaml=./mini_nonrf_config_3slices.yaml
kubectl apply -f upf-deployment.yaml

upf_pod=$(get_pod_name "oai-upf")
if [ -n "$upf_pod" ]; then
  wait_for_pod "$upf_pod"
else
  echo "upf pod with prefix 'oai-upf' not found."
fi

kubectl create configmap smf-config --from-file=mini_nonrf_config_3slices.yaml=./mini_nonrf_config_3slices.yaml
kubectl apply -f smf-deployment.yaml

smf_pod=$(get_pod_name "oai-smf")
if [ -n "$smf_pod" ]; then
  wait_for_pod "$smf_pod"
else
  echo "smf pod with prefix 'oai-smf' not found."
fi

#kubectl apply -f ext-dn-deployment.yaml

#ext_dn_pod=$(get_pod_name "oai-ext-dn")
#if [ -n "$ext_dn_pod" ]; then
  #wait_for_pod "$ext_dn_pod"
#else
  #echo "smf pod with prefix 'oai-ext-dn' not found."
#fi

sleep 10

echo "Fetching logs for 5gc pods..."

if [ -n "$mysql_pod" ]; then
  display_logs "$mysql_pod" | tail
  kubectl exec -it  "$mysql_pod" -- /bin/bash -c "mysql -utest -ptest -e 'show databases; use oai_db; show tables; describe users;'"
fi

if [ -n "$amf_pod" ]; then
  display_logs "$amf_pod" | tail
fi

if [ -n "$upf_pod" ]; then
  display_logs "$upf_pod" | tail
fi

if [ -n "$smf_pod" ]; then
  display_logs "$smf_pod" | tail
fi

#if [ -n "$ext_dn_pod" ]; then
  #display_logs "$ext_dn_pod" | tail
#fi

kubectl get pods -o wide
