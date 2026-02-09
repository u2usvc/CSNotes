# Troubleshooting

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

## troubleshoot DiskPressure taint on a node

<https://kubernetes.io/blog/2024/01/23/kubernetes-separate-image-filesystem/>
The following means that the node lacks 1Gi to run Pods

```bash
kubectl describe nodes coreos02
# Events:
#   Warning  FreeDiskSpaceFailed      69s                 kubelet          Failed to garbage collect required amount of images. Attempted to free 1339201945 bytes, but only found 0 bytes eligible to free.
```

In order to fix this,

1) attach larger disk to a libvirt_domain
2) configure cri-o (or other container runtime) to use a directory on a new disk for containers
<https://github.com/cri-o/cri-o/blob/main/docs/crio.conf.5.md>

```bash
### /etc/crio/crio.conf
# see `man containers-storage.conf`
[crio]
# Default storage driver
storage_driver = "overlay"
# Temporary storage location (default: "/run/containers/storage")
runroot = "/var/run/containers/storage"
# Primary read/write location of container storage (default:  "/var/lib/containers/storage")
root = "/var/lib/containers/storage"
```
