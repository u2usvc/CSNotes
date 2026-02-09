# Admin

## add custom CA if there are no init containers that run update-ca-certificates for the pod

```bash
kubectl -n gitea patch deployment gitea \
--type='json' \
-p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "internal-root-ca",
      "configMap": {
        "name": "internal-root-ca"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ca-store",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
"name": "ca-store",
      "mountPath": "/etc/ssl/certs/",
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/initContainers/-",
    "value": {
      "name": "build-ca",
      "image": "docker.io/fluxcd/flux:1.17.0",
      "imagePullPolicy": "IfNotPresent",
      "command": ["/usr/sbin/update-ca-certificates"],
      "volumeMounts": [
        {
          "mountPath": "/usr/local/share/ca-certificates/",
          "name": "internal-root-ca",
          "readOnly": true
        },
        {
          "mountPath": "/etc/ssl/certs/",
          "name": "ca-store"
        }
      ]
    }
  }
]'
```

## prevent namespace stuck in terminating

```bash
kubectl get namespace $NAMESPACE -o json > ns.json

nvim ns.json
# "finalizers": []

kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f ./ns.json
```
