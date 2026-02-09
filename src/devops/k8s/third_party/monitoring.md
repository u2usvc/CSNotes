# Monitoring

## Prometheus & Grafana

### Setup

```bash
kubectl create namespace monitoring
kubectl label namespace monitoring istio-injection=enabled
kubectl label --overwrite namespace monitoring \
pod-security.kubernetes.io/enforce=privileged \
pod-security.kubernetes.io/enforce-version=latest

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus --namespace monitoring

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
--namespace monitoring \
--set persistence.enabled=true

kubectl apply -f grafana-ingress.yaml

# get passwd
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

login via `admin:passwd`
Add node exporter dashboard
Add prometheus data source with `http://prometheus-server.monitoring.svc.cluster.local`

Grafana authentik integration requires values.yaml modification, ao i will refer to Authentik docs to undate the deployment:

```bash
kubectl create secret generic grafana-authentik-secret -n monitoring --from-literal=client_secret='REDACTED'

# we will make gitea use root CA for it to trust authentik
kubectl label namespace monitoring use-internal-ca=true
kubectl -n monitoring edit deployment grafana
# spec:
#   template:
#     spec:
#       volumes:
#         - name: internal-ca
#           configMap:
#             name: internal-root-ca
#       containers:
#         - env:
#           name: grafana
#           volumeMounts:
#             - name: internal-ca
#               mountPath: /etc/ssl/certs/internal-ca.crt
#               subPath: ca.crt
#               readOnly: true

# as grafana is behind istio, we have to specify root_url, otherwise it redirects to localhost:3000
nvim grafana-values.yaml
# grafana.ini:
#   server:
#     root_url: https://grafana.aperture.ad
#   auth:
#     signout_redirect_url: "https://authentik.aperture.ad/application/o/grafana/end-session/"
#     oauth_auto_login: false
#   auth.generic_oauth:
#     name: authentik
#     enabled: true
#     client_id: "TiLrd2FQwovZOYfHdIm2DLk3i2QVQeXWjaYd4nW9"
#     client_secret: $__file{/etc/secrets/authentik/client_secret}
#     scopes: "openid profile email"
#     auth_url: "https://authentik.aperture.ad/application/o/authorize/"
#     token_url: "https://authentik.aperture.ad/application/o/token/"
#     api_url: "https://authentik.aperture.ad/application/o/userinfo/"
# 
# extraSecretMounts:
#   - name: authentik-secret
#     secretName: grafana-authentik-secret
#     mountPath: /etc/secrets/authentik
#     readOnly: true
# extraConfigmapMounts:
#   - name: internal-ca
#     configMap: internal-root-ca
#     mountPath: /etc/ssl/certs/internal-ca.crt
#     subPath: ca.crt
#     readOnly: true

helm upgrade grafana grafana/grafana -n monitoring --set persistence.enabled=true -f grafana-values.yaml
```
