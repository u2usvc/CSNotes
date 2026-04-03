# Log Management

## Loki & Alloy

### Setup

First, Loki needs S3-compatible object storage. For that I will deploy rook-ceph RGW:

```bash
# ---
# cat rook-objectstore*
# apiVersion: ceph.rook.io/v1
# kind: CephObjectStoreUser
# metadata:
#   name: loki-user
#   namespace: rook-ceph
# spec:
#   store: ceph-objectstore
#   displayName: "Loki S3 User"
# ---
# apiVersion: ceph.rook.io/v1
# kind: CephObjectStore
# metadata:
#   name: ceph-objectstore
#   namespace: rook-ceph
# spec:
#   metadataPool:
#     failureDomain: host
#     replicated:
#       size: 2
#   dataPool:
#     failureDomain: host
#     replicated:
#       size: 2
#   gateway:
#     port: 80
#     instances: 1

kubectl apply -f rook-objectstore.yaml

# wait for it to deploy
watch kubectl -n rook-ceph get secret

# retrieve creds
kubectl -n rook-ceph get secret rook-ceph-object-user-ceph-objectstore-loki-user -o jsonpath='{.data.AccessKey}' | base64 -d
kubectl -n rook-ceph get secret rook-ceph-object-user-ceph-objectstore-loki-user -o jsonpath='{.data.SecretKey}' | base64 -d
```

```bash
kubectl create ns loki
kubectl label namespace loki istio-injection=enabled

cat loki-values.yaml
# loki:
#   auth_enabled: false
#   commonConfig:
#     path_prefix: /var/loki
#     replication_factor: 1   # set this to 1 if you only have 1 write pod (`write.replicas=1`)
#   server:
#     http_listen_port: 3100
#   schemaConfig:
#     configs:
#       - from: "2024-01-01"
#         store: tsdb
#         object_store: s3
#         schema: v13
#         index:
#           prefix: index_
#           period: 24h
#   limits_config:
#     retention_period: 24h
#   compactor:
#     retention_enabled: true
#     delete_request_store: s3
#   storage:
#     type: s3
#     bucketNames:
#       chunks: loki-chunks
#       ruler: loki-ruler
#       admin: loki-admin
#     s3:
#       endpoint: http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc.cluster.local
#       accessKeyId: $ACCESSKEY
#       secretAccessKey: $SECRETKEY
#       s3ForcePathStyle: true  # required for Ceph RGW - it does not support virtual-hosted style URLs
#       insecure: true          # RGW endpoint is plain HTTP inside the cluster
# 
# write:
#   persistence:
#     volumeClaimsEnabled: false  # log data goes to object storage, no PVCs needed
# 
# read:
#   persistence:
#     volumeClaimsEnabled: false
# 
# backend:
#   persistence:
#     volumeClaimsEnabled: false
# 
# gateway:
#   enabled: true
#   replicas: 1
#   ingress:
#     enabled: true
#     ingressClassName: istio
#     hosts:
#       - host: loki.aperture.ad
#         paths:
#           - path: /
#             pathType: Prefix

helm install loki grafana/loki -n loki -f loki-values.yaml
```

minio buckets would be created automatically, but `minio.enabled=false` is set, S3 buckets need to be created manually before loki starts. We gotta spawn the `amazon/aws-cli` container to send an S3 `make bucket` (mb) request to ceph RGW

```bash
for bucket in loki-chunks loki-ruler loki-admin; do
  kubectl run s3-init -n rook-ceph --restart=Never --image=amazon/aws-cli:latest \
    --overrides="{\"spec\":{\"containers\":[{\"name\":\"s3-init\",\"image\":\"amazon/aws-cli:latest\",\"command\":[\"aws\"],\"args\":[\"--endpoint-url\",\"http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc:80\",\"--region\",\"us-east-1\",\"s3\",\"mb\",\"s3://${bucket}\"],\"env\":[{\"name\":\"AWS_ACCESS_KEY_ID\",\"value\":\"${ACCESSKEY}\"},{\"name\":\"AWS_SECRET_ACCESS_KEY\",\"value\":\"${SECRETKEY}\"}]}]}}"
  kubectl wait -n rook-ceph pod/s3-init --for=condition=Ready --timeout=60s
  kubectl logs -n rook-ceph s3-init
  kubectl delete pod s3-init -n rook-ceph
done

kubectl -n loki rollout restart deployment/loki-read
```

Add grafana Loki source with `http://loki-gateway.loki.svc.cluster.local`

```bash
helm install alloy grafana/alloy \
--namespace monitoring \
--values alloy-values.yaml

kubectl get pods -n monitoring -l app.kubernetes.io/name=alloy
```
