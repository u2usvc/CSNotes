# IdP

## Authentik

### Setup with gitea

```bash
nvim authentic-values.yaml
# authentik:
#   secret_key: "somekey"
#   # This sends anonymous usage-data, stack traces on errors and
#   # performance data to sentry.io, and is fully opt-in
#   error_reporting:
#     enabled: true
#   postgresql:
#     password: "somepass"
# 
# postgresql:
#   enabled: true
#   auth:
#     password: "somepass"
# redis:
#   enabled: true

helm upgrade --install authentik authentik/authentik \
--namespace authentik \
-f authentik-values.yaml

nvim authentik-ingress.yaml
# apiVersion: networking.istio.io/v1beta1
# kind: Gateway
# metadata:
#   name: authentik-gateway
#   namespace: authentik
# spec:
#   selector:
#     istio: ingressgateway
#   servers:
#     - port:
#         number: 80
#         name: http
#         protocol: HTTP
#       hosts:
#         - "authentik.aperture.ad"
#       tls:
#         httpsRedirect: true
#     - port:
#         number: 443
#         name: https
#         protocol: HTTPS
#       hosts:
#         - "authentik.aperture.ad"
#       tls:
#         mode: SIMPLE
#         credentialName: authentik-tls
# ---
# apiVersion: networking.istio.io/v1beta1
# kind: VirtualService
# metadata:
#   name: authentik
#   namespace: authentik
# spec:
#   hosts:
#     - "authentik.aperture.ad"
#   gateways:
#     - authentik-gateway
#   http:
#     - match:
#         - uri:
#             prefix: /
#       route:
#         - destination:
#             host: authentik.svc.cluster.local
#             port:
#               number: 80
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: authentik-cert
#   namespace: istio-system
# spec:
#   secretName: authentik-tls
#   issuerRef:
#     name: internal-ca-issuer
#     kind: ClusterIssuer
#   commonName: authentik.aperture.ad
#   dnsNames:
#     - authentik.aperture.ad


kubectl apply -f authentik-ingress.yaml
```

Access authentik by navigating to `https://authentik.aperture.ad/if/flow/initial-setup/`
Add gitea provider and add gitea application, assign the provider to an application.
