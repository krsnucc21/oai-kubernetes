#!/bin/bash

# Get the list of all pods in the default namespace
pods=$(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

# Iterate over each pod to get the interface names and IP addresses
echo "Namespace | Pod Name | Interface Name | IP Address"
echo "-------------------------------------------------"

while IFS= read -r pod; do
    namespace=$(echo $pod | awk '{print $1}')
    name=$(echo $pod | awk '{print $2}')
    
    # Attempt to run 'ifconfig' command in the pod
    output=$(kubectl exec -n $namespace $name -- sh -c 'ifconfig' 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        # If the 'ifconfig' command fails, print the namespace and pod name
        echo "$namespace | $name | ifconfig command not found"
    else
        # Process the output of the 'ifconfig' command to get interface names and IP addresses
        echo "$output" | awk '/^[a-zA-Z0-9]/ {iface=$1} /inet / {print iface, $2}' | while read -r line; do
            interface=$(echo $line | awk '{print $1}')
            ip=$(echo $line | awk '{print $2}')
            echo "$namespace | $name | $interface | $ip"
        done
    fi
done <<< "$pods"
