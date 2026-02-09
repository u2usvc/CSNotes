# Cert Managers

## cert-manager

### Setting up certificates for Gitea

```bash
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
--namespace cert-manager \
--create-namespace \
--set crds.enabled=true

# define issuers and certificate for gitea
nvim cert-manager-gitea.yaml
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: internal-ca
# spec:
#   selfSigned: {}
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: internal-ca
#   namespace: cert-manager
# spec:
#   secretName: internal-ca-key-pair
#   commonName: "Aperture Root CA"
#   isCA: true
#   issuerRef:
#     name: internal-ca
#     kind: ClusterIssuer
# ---
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: internal-ca-issuer
# spec:
#   ca:
#     secretName: internal-ca-key-pair
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: gitea-cert
#   namespace: istio-system
# spec:
#   secretName: gitea-tls
#   issuerRef:
#     name: internal-ca-issuer
#     kind: ClusterIssuer
#   commonName: gitea.aperture.ad
#   dnsNames:
#     - gitea.aperture.ad

# update gitea gateway to use it
kubectl -n gitea edit gw gitea-gateway
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
#       tls:
#         httpsRedirect: true
#     - port:
#         number: 443
#         name: https
#         protocol: HTTPS
#       hosts:
#         - "gitea.aperture.ad"
#       tls:
#         mode: SIMPLE
#         credentialName: gitea-tls

kubectl -n cert-manager get secret internal-ca-key-pair -o jsonpath='{.data.ca\.crt}' | base64 -d > k8s-aperture-root-ca.crt
sudo cp k8s-aperture-root-ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
# additionally, import this CA into your browser
```

### trust-manager

#### Usage example

Before proceeding to configure OIDC on the application-side, we need to ensure that application trusts the authentiks certificates issuer.
In order to archieve that I will use `trust-manager`

```bash
helm upgrade trust-manager jetstack/trust-manager \
--install \
--namespace cert-manager

nvim ca-bundle.yaml
# apiVersion: trust.cert-manager.io/v1alpha1
# kind: Bundle
# metadata:
#   name: internal-root-ca
# spec:
#   sources:
#     - secret:
#         name: internal-ca-key-pair
#         key: tls.crt
#   target:
#     configMap:
#       key: ca.crt
# namespaceSelector:
#   matchLabels:
#     use-internal-ca: "true"

kubectl apply -f ca-bundle.yaml

kubectl label namespace gitea use-internal-ca=true
kubectl label namespace authentik use-internal-ca=true

kubectl -n gitea describe configmap internal-root-ca

# mount the configmap to as a volume
kubectl -n gitea edit deployment gitea
# spec:
#   template:
#     spec:
#       volumes:
#         - name: internal-ca
#           configMap:
#             name: internal-root-ca
#       containers:
#         - env:
#           name: gitea
#           volumeMounts:
#             - name: internal-ca
#               mountPath: /etc/ssl/certs/internal-ca.crt
#               subPath: ca.crt
#               readOnly: true

kubectl -n gitea patch deployment authentik-server --type='json' \
-p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "internal-ca",
      "configMap": {
        "name": "internal-root-ca"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "internal-ca",
      "mountPath": "/etc/ssl/certs/internal-ca.crt",
      "subPath": "ca.crt",
      "readOnly": true
    }
  }
]'
```
