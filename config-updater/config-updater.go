package main

import (
    "context"
    "fmt"
    "net"
    "os"
    "os/exec"
    "strings"
    "time"

    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
    "k8s.io/client-go/tools/clientcmd"
    "k8s.io/klog/v2"
)

func main() {
    // Get environment variables
    nodeType := os.Getenv("NODE_TYPE")
    configMapName := os.Getenv("IP_CONFIGMAP_NAME")
    configMapNamespace := os.Getenv("CONFIGMAP_NAMESPACE")
    gnbConfigMapName := os.Getenv("GNB_CONFIGMAP_NAME")

    // Load kubeconfig
    config, err := getKubeConfig()
    if err != nil {
        panic(err.Error())
    }

    // Create a clientset
    clientset, err := kubernetes.NewForConfig(config)
    if err != nil {
        panic(err.Error())
    }

    // Get host IP address
    ip, err := getHostIP()
    if err != nil {
        panic(err.Error())
    }

    // Update the configmap
    ctx := context.TODO()
    for {
        cm, err := clientset.CoreV1().ConfigMaps(configMapNamespace).Get(ctx, configMapName, metav1.GetOptions{})
        if err != nil {
            panic(err.Error())
        }

        if nodeType == "cu" {
            cm.Data["cu-ip"] = ip
        } else {
            cm.Data["du-ip"] = ip
        }

        _, err = clientset.CoreV1().ConfigMaps(configMapNamespace).Update(ctx, cm, metav1.UpdateOptions{})
        if err != nil {
            panic(err.Error())
        }

        // Wait for the other data to be updated
        if nodeType == "cu" {
            if cm.Data["du-ip"] != "" {
                fmt.Println("Both IPs are updated:", cm.Data)
                runConfigUpdateCommands(clientset, configMapNamespace, gnbConfigMapName, cm.Data["cu-ip"], cm.Data["du-ip"])
                break
            }
        } else {
            if cm.Data["cu-ip"] != "" {
                fmt.Println("Both IPs are updated:", cm.Data)
                runConfigUpdateCommands(clientset, configMapNamespace, gnbConfigMapName, cm.Data["cu-ip"], cm.Data["du-ip"])
                break
            }
        }

        time.Sleep(5 * time.Second) // Polling interval
    }
}

func getKubeConfig() (*rest.Config, error) {
    // Check if running inside Kubernetes cluster
    if _, err := rest.InClusterConfig(); err == nil {
        klog.Info("Using in-cluster configuration")
        return rest.InClusterConfig()
    }

    // Fallback to kubeconfig file
    kubeconfig := os.Getenv("KUBECONFIG")
    if kubeconfig == "" {
        home := os.Getenv("HOME")
        kubeconfig = fmt.Sprintf("%s/.kube/config", home)
    }
    return clientcmd.BuildConfigFromFlags("", kubeconfig)
}

func getHostIP() (string, error) {
    addrs, err := net.InterfaceAddrs()
    if err != nil {
        return "", err
    }

    for _, addr := range addrs {
        if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
            if ipNet.IP.To4() != nil {
                return ipNet.IP.String(), nil
            }
        }
    }

    return "", fmt.Errorf("no IP address found")
}

func runConfigUpdateCommands(clientset *kubernetes.Clientset, namespace, configMapName, cuIP, duIP string) {
    ctx := context.TODO()

    // Get the AMF IP address
    amfIPCmd := exec.Command("sh", "-c", "getent hosts oai-amf | awk '{print $1}'")
    amfIP, err := amfIPCmd.Output()
    if err != nil {
        fmt.Printf("Error getting OAI-AMF IP: %v\n", err)
        return
    }
    amfIPStr := strings.TrimSpace(string(amfIP))

    // Get the specific ConfigMap (cu-config or du-config)
    cm, err := clientset.CoreV1().ConfigMaps(namespace).Get(ctx, configMapName, metav1.GetOptions{})
    if err != nil {
        panic(err.Error())
    }

    // Replace placeholders in the ConfigMap data
    for key, value := range cm.Data {
        value = strings.ReplaceAll(value, "$(OAI-DU)", duIP)
        value = strings.ReplaceAll(value, "$(OAI-CU)", cuIP)
        value = strings.ReplaceAll(value, "$(OAI-AMF)", amfIPStr)
        cm.Data[key] = value
    }

    // Update the ConfigMap
    _, err = clientset.CoreV1().ConfigMaps(namespace).Update(ctx, cm, metav1.UpdateOptions{})
    if err != nil {
        panic(err.Error())
    }

    fmt.Printf("ConfigMap %s updated successfully\n", configMapName)
}
