# Service Mesh

## Istio

### Gitea setup

deploy gitea:
[https://gitea.com/gitea/helm-gitea#persistence](https://gitea.com/gitea/helm-gitea#persistence), [https://gitea.com/gitea/helm-gitea/src/branch/main/values.yaml](https://gitea.com/gitea/helm-gitea/src/branch/main/values.yaml)

```bash
# create a namespace for gitea
kubectl create namespace gitea

# deploy gitea specifying the storageClass: this will enable gitea to create a PersistentVolumeClaim that will request a PersitentVolume
# from a specific rook-ceph-block StorageClass that we created earlier
helm install gitea gitea-charts/gitea \
--namespace gitea \
--create-namespace \
--set postgresql-ha.enabled=false \
--set postgresql.enabled=true \
--set persistence.storageClass='rook-ceph-block' \
--set postgresql.primary.persistence.storageClass='rook-ceph-block' \
--set valkey-cluster.persistence.storageClass='rook-ceph-block' \
--set gitea.config.server.ROOT_URL=https://gitea.aperture.ad/
```

Let's now configure Istio for ingress:
[https://istio.io/latest/docs/setup/install/helm/#installation-steps](https://istio.io/latest/docs/setup/install/helm/#installation-steps)

```bash
kubectl create namespace istio-system
kubectl label --overwrite namespace istio-system \
pod-security.kubernetes.io/enforce=privileged \
pod-security.kubernetes.io/enforce-version=latest

istioctl install --set components.cni.enabled=true -y
```

now expose gitea
[https://istio.io/latest/docs/setup/additional-setup/pod-security-admission/#install-istio-with-psa](https://istio.io/latest/docs/setup/additional-setup/pod-security-admission/#install-istio-with-psa)

```bash
# istio sidecar mode routes traffic only for workloads with sidecars injected
# Enable sidecar injection for pods in a namespace:
kubectl label namespace gitea istio-injection=enabled

# verify injection is enabled for the namespace
kubectl get namespace -L istio-injection

kubectl -n gitea get pods
kubectl -n gitea delete pod gitea-6fb84975c6-d4tzv

nvim gitea-ingress.yaml
# apiVersion: networking.istio.io/v1beta1
# kind: Gateway
# metadata:
#   name: gitea-gateway
#   namespace: gitea
# spec:
#   selector:
#     istio: ingressgateway
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - "gitea.aperture.ad"
# ---
# apiVersion: networking.istio.io/v1beta1
# kind: VirtualService
# metadata:
#   name: gitea
#   namespace: gitea
# spec:
#   hosts:
#     - "gitea.aperture.ad"
#   gateways:
#     - gitea-gateway
#   http:
#     - match:
#         - uri:
#             prefix: /
#       route:
#         - destination:
#             host: gitea-http.gitea.svc.cluster.local
#             port:
#               number: 3000


kubectl apply -f gitea-ingress.yaml

# ensure that istio-proxy is a part of Init Containers
kubectl -n gitea describe pod gitea-6fb84975c6-lxb6b

kubectl -n gitea get vs
```

Currently, ingress type is LoadBalancer

```bash
kubectl -n istio-system get svc istio-ingressgateway
# NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                      AGE
# istio-ingressgateway   LoadBalancer   10.108.215.121   <pending>     15021:30679/TCP,80:30864/TCP,443:30769/TCP   11h

cat /etc/hosts
# 192.168.88.243 gitea.aperture.ad
```

### Kiali

#### Setup

```bash
cd istio/
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system
istioctl dashboard kiali
```
