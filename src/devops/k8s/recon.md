# Recon

## Basic

### DNS enum

- find out nameserver

```bash
cat /etc/resolv.conf
# search k8s-lan-party.svc.cluster.local svc.cluster.local cluster.local us-west-1.compute.internal
# nameserver 10.100.120.34
# options ndots:5
```

- if you already know the hostname you want to resolve and have the necessary utility to make a request:

```bash
dig @10.100.120.34 getflag-service.k8s-lan-party.svc.cluster.local | grep -A1 "ANSWER SECTION"
# ;; ANSWER SECTION:
# getflag-service.k8s-lan-party.svc.cluster.local. 30 IN A 10.100.136.254
```

- if you know the IP address you want to get a DNS name of perform a reverse DNS lookup (PTR record):

```bash
dig @10.100.120.34 -x 10.100.136.254 | grep -A1 "ANSWER SECTION"
# ;; ANSWER SECTION:
# 254.136.100.10.in-addr.arpa. 15 IN      PTR     getflag-service.k8s-lan-party.svc.cluster.local
```

- Or perform reverse lookups for a CIDR via dnscan:

```bash
dnscan -subnet 10.100.0.1/16
```

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

### Initial from within a container

- `/etc/resolv.conf` -> `search` property can give up coreDNS' root.

```bash
# If you have access to /etc/resolv.conf - check if there is 'search ...' - there will be core DNS for K8s
# e.g. if `search ... XXX.YYY`, then
# API might be located at kubernetes.default.svc.XXX.YYY:443
cat /etc/resolv.conf
# search default.svc.cluster.local svc.cluster.local cluster.local kubernetes.org
# nameserver 10.96.0.10
# options ndots:5

# query the apiserver certificate
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

curl -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" --insecure https://kubernetes.default.svc.cluster.local
# {
#   "kind": "Status",
#   "apiVersion": "v1",
#   "metadata": {},
#   "status": "Failure",
#   "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/\"",
#   "reason": "Forbidden",
#   "details": {},
#   "code": 403
# }
```

- `set` -> `KUBERNETES_XXX` environment variables will giveup kube-proxy address and let you make requests to kube-apiserver from within a pod

```bash
root@nginx-test-574bc578fc-dbsh7:/# set | grep KUBERNETES
# KUBERNETES_PORT=tcp://10.96.0.1:443
# KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
# KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
# KUBERNETES_PORT_443_TCP_PORT=443
# KUBERNETES_PORT_443_TCP_PROTO=tcp
# KUBERNETES_SERVICE_HOST=10.96.0.1
# KUBERNETES_SERVICE_PORT=443
# KUBERNETES_SERVICE_PORT_HTTPS=443

root@nginx-test-574bc578fc-dbsh7:/# curl --insecure https://10.96.0.1
# {
#   "kind": "Status",
#   "apiVersion": "v1",
#   "metadata": {},
#   "status": "Failure",
#   "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
#   "reason": "Forbidden",
#   "details": {},
#   "code": 403
# }

root@nginx-test-574bc578fc-dbsh7:/# curl -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" --insecure https://10.96.0.1
# {
#   "kind": "Status",
#   "apiVersion": "v1",
#   "metadata": {},
#   "status": "Failure",
#   "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/\"",
#   "reason": "Forbidden",
#   "details": {},
#   "code": 403
# }
```

- `/etc/fstab` can giveup volume mount locations

- in a container, all pod's secret should be located under `/run/secrets/kubernetes.io/serviceaccount/` directory

```bash
root@nginx-test-574bc578fc-dbsh7:/run/secrets/kubernetes.io/serviceaccount# ls -la
# drwxr-xr-x 2 root root  100 Oct 15 17:14 ..2024_10_15_17_14_13.1702215151
# lrwxrwxrwx 1 root root   32 Oct 15 17:14 ..data -> ..2024_10_15_17_14_13.1702215151
# lrwxrwxrwx 1 root root   13 Oct  7 10:02 ca.crt -> ..data/ca.crt
# lrwxrwxrwx 1 root root   16 Oct  7 10:02 namespace -> ..data/namespace
# lrwxrwxrwx 1 root root   12 Oct  7 10:02 token -> ..data/token
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

### mount discovery

```bash
df
cat /etc/fstab
lsblk              # will probably fail


df
# Filesystem                                                1K-blocks    Used        Available Use% Mounted on
# overlay                                                   314560492 8837544        305722948   3% /
# fs-0779524599b7d5e7e.efs.us-west-1.amazonaws.com:/ 9007199254739968       0 9007199254739968   0% /efs
# tmpfs                                                      62022172      12         62022160   1% /var/run/secrets/kubernetes.io/serviceaccount
# tmpfs                                                         65536       0            65536   0% /dev/null

dig fs-0779524599b7d5e7e.efs.us-west-1.amazonaws.com | grep -A1 "ANSWER SECTION"
# fs-0779524599b7d5e7e.efs.us-west-1.amazonaws.com. 23 IN A 192.168.124.98
```

### sidecar discovery

- all containers under the Pod share same net namespace

```bash
# the following displays /31 subnet, that means that 192.168.28.66 is a neighbor peer
ifconfig
# ns-564e82: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
#     inet 192.168.28.67  netmask 255.255.255.254  broadcast 0.0.0.0
```
