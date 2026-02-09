# Recon

## Basic

### General

```bash
# A) get username and (cluster)roles/(cluster)rolebindings you're in
kubectl auth whoami

# A) List all allowed actions in namespace "foo"
kubectl auth can-i --list --namespace 'foo'

# A) get current config that kubectl uses
kubectl config view
# if it's not successfull try grepping env/set for KUBECONFIG

# A) get all resource types available
kubectl api-resources

# A) get resources of kind
kubectl get configmaps --all-namespaces

# A) get contents of a specific object after you got the name using GET verb
kubectl describe configmap --namespace kube-system coredns

# A) get full secret
kubectl get secret sh.helm.release.v1.fluentd.v1 -o yaml
```

### access a pod's webservice using curl

```bash
kubectl get services --all-namespaces
# NAMESPACE     NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
# monitoring    grafana         ClusterIP   10.99.24.78      <none>        80/TCP 

kubectl describe service --namespace monitoring grafana
# Name:              grafana
# Namespace:         monitoring
# Labels:            app.kubernetes.io/instance=grafana
# app.kubernetes.io/managed-by=Helm
# app.kubernetes.io/name=grafana
# app.kubernetes.io/version=11.5.2
# helm.sh/chart=grafana-8.10.3
# Annotations:       meta.helm.sh/release-name: grafana
# meta.helm.sh/release-namespace: monitoring
# Selector:          app.kubernetes.io/instance=grafana,app.kubernetes.io/name=grafana
# Type:              ClusterIP
# IP Family Policy:  SingleStack
# IP Families:       IPv4
# IP:                10.99.24.78
# IPs:               10.99.24.78
# Port:              service  80/TCP
# TargetPort:        3000/TCP
# Endpoints:         10.244.1.186:3000
# Session Affinity:  None
# Events:            <none>

curl http://10.99.24.78
# <a href="/login">Found</a>
```

### determine what serviceAccount the Pod is using

```bash
kubectl get pods/$POD_NAME -o yaml | yq .spec.serviceAccountName
```

### find your permissions

```bash
kubectl auth whoami
# ATTRIBUTE   VALUE
# Username    kubernetes-admin
# Groups      [kubeadm:cluster-admins system:authenticated]

# first figure out if anything apart from RBAC (default is "Node,RBAC") is used:
# it can either be defined by using AuthorizationConfiguration resource 
# or kube-apiserver command-line parameters defined in it's manifest on master-node
kubectl get authorizationconfigurations
cat /etc/kubernetes/manifests/kube-apiserver.yaml


# the following means that kubeadm:cluster-admins is a ClusterRoleBinding that points to cluster-admin ClusterRole 
# OMMIT THE "s"
kubectl get clusterrolebindings -A | grep kubeadm:cluster-admin
# kubeadm:cluster-admins          ClusterRole/cluster-admin

# cluster-admin ClusterRole can use ['*'] verbs on ['*'] api-resources, this is boring
# just for the sake of an example (of course it doesn't), 
# let's say that cluster-admins binds to ClusterRole/cilium-operator:

# the following means cilium-operator can CREATE/GET/LIST/WATCH customresourcedefinitions and 
# UPDATE specific resource named ciliumnodes
# which are contained within apiextensions.k8s.io APIVERSION
kubectl describe clusterrole cilium-operator
# Name:         cilium-operator
# Labels:       app.kubernetes.io/managed-by=Helm
# Resources                                          Non-Resource URLs  Resource Names           Verbs
# ---------                                          -----------------  --------------           -----
# customresourcedefinitions.apiextensions.k8s.io     []                 []                       [create get list watch]
# customresourcedefinitions.apiextensions.k8s.io     []                 [ciliumnodes.cilium.io]  [update]

# if the following doesn't give anything it probably (???) means the resource 
# was not created in your environment during package installation
kubectl get customresourcedefinitions | grep ciliumnodes
# ciliumnodes.cilium.io                        2024-10-06T12:55:42Z

# print object definition
kubectl describe customresourcedefinitions ciliumnodes | less
```
