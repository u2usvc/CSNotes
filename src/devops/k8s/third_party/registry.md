# Registries

## Harbor

### Setup

```bash
kubectl create namespace harbor
kubectl label namespace harbor istio-injection=enabled

# make sure to use tun throne
helm repo add harbor https://helm.goharbor.io

helm upgrade --namespace harbor --install harbor harbor/harbor --set expose.type=clusterIP --set expose.clusterIP.name=harbor --set expose.tls.enabled=false --set externalURL=https://harbor.aperture.ad

cat harbor-ingress.yaml
# apiVersion: networking.istio.io/v1beta1
# kind: Gateway
# metadata:
#   name: harbor-gateway
#   namespace: harbor
# spec:
#   selector:
#     istio: ingressgateway
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - "harbor.aperture.ad"
#       tls:
#         httpsRedirect: true
#     - port:
#         number: 443
#         name: https
#         protocol: HTTPS
#       hosts:
#         - "harbor.aperture.ad"
#       tls:
#         mode: SIMPLE
#         credentialName: harbor-tls
# ---
# apiVersion: networking.istio.io/v1beta1
# kind: VirtualService
# metadata:
#   name: harbor
#   namespace: harbor
# spec:
#   hosts:
#     - "harbor.aperture.ad"
#   gateways:
#     - harbor-gateway
#   http:
#     - match:
#         - port: 443
#           uri:
#             prefix: /
#       route:
#         - destination:
#             host: harbor.harbor.svc.cluster.local
#             port:
#               number: 80
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: harbor-cert
#   namespace: istio-system
# spec:
#   secretName: harbor-tls
#   issuerRef:
#     name: internal-ca-issuer
#     kind: ClusterIssuer
#   commonName: harbor.aperture.ad
#   dnsNames:
#     - harbor.aperture.ad

kubectl apply -f harbor-ingress.yaml

docker login https://harbor.aperture.ad
# Username: admin
# Password:
```

## Nexus

### Setup

8384 port is an additional HTTPS port for Docker

```bash
kubectl create namespace nexus
kubectl label namespace nexus istio-injection=enabled

helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm upgrade --install --namespace nexus nexus-repo sonatype/nexus-repository-manager

nvim nexus-ingress.yaml
# apiVersion: networking.istio.io/v1beta1
# kind: Gateway
# metadata:
#   name: nexus-gateway
#   namespace: nexus
# spec:
#   selector:
#     istio: ingressgateway
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - "nexus.aperture.ad"
#       tls:
#         httpsRedirect: true
#     - port:
#         number: 443
#         name: https
#         protocol: HTTPS
#       hosts:
#         - "nexus.aperture.ad"
#       tls:
#         mode: SIMPLE
#         credentialName: nexus-tls
#     - port:
#         number: 8384
#         name: https-8384
#         protocol: HTTPS
#       hosts:
#         - "nexus.aperture.ad"
#       tls:
#         mode: SIMPLE
#         credentialName: nexus-tls
# ---
# apiVersion: networking.istio.io/v1beta1
# kind: VirtualService
# metadata:
#   name: nexus
#   namespace: nexus
# spec:
#   hosts:
#     - "nexus.aperture.ad"
#   gateways:
#     - nexus-gateway
#   http:
#     - match:
#         - port: 443
#           uri:
#             prefix: /
#       route:
#         - destination:
#             host: nexus-repo-nexus-repository-manager.nexus.svc.cluster.local
#             port:
#               number: 8081
#     - match:
#         - port: 8384
#           uri:
#             prefix: /
#       route:
#         - destination:
#             host: nexus-repo-nexus-repository-manager.nexus.svc.cluster.local
#             port:
#               number: 8384
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: nexus-cert
#   namespace: istio-system
# spec:
#   secretName: nexus-tls
#   issuerRef:
#     name: internal-ca-issuer
#     kind: ClusterIssuer
#   commonName: nexus.aperture.ad
#   dnsNames:
#     - nexus.aperture.ad


kubectl apply -f nexus-ingress.yaml

kubectl -n nexus patch service nexus-repo-nexus-repository-manager \
--type='json' -p='[{"op": "replace", "path": "/spec/ports/0/name", "value": "http-nexus"}]'

kubectl -n istio-system patch svc istio-ingressgateway --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/ports/-",
    "value": {
      "name": "https-8384",
      "port": 8384,
      "targetPort": 8384,
      "protocol": "TCP"
    }
  }
]'

kubectl -n nexus patch svc nexus-repo-nexus-repository-manager --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/ports/-",
    "value": {
      "name": "https-8384",
      "port": 8384,
      "targetPort": 8384,
      "protocol": "TCP"
    }
  }
]'

kubectl -n nexus exec -it pod/nexus-repo-nexus-repository-manager-55b69ddd87-nlxth -- cat /nexus-data/admin.password
```
