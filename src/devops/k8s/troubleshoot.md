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

## fix minikube volumeMounts permission errors

Add gitea:
`valkey.volumePermissions.enabled` - Enable init container that changes the owner/group of the PV mount point to `runAsUser:fsGroup` on valkey containers.

```bash
helm upgrade --install gitea gitea-charts/gitea \
--namespace gitea --create-namespace \
--set postgresql-ha.enabled=false \
--set postgresql.enabled=true \
--set gitea.config.server.ROOT_URL=https://gitea.aperture.ad/ \
--set valkey-cluster.enabled=false --set valkey.volumePermissions.enabled=true \
--set valkey.enabled=true --set gitea.config.server.ROOT_URL=https://gitea.minikube.lab/
```

Errors:

```bash
kubectl -n gitea logs gitea-68577d9b9-ssmjh -c init-directories
# mkdir: can't create directory '/data/git/': Permission denied
```

I've tried to debug by displaying the directory permissions:

```bash
EDITOR=nvim kubectl -n gitea edit deploy gitea
#       initContainers:
#       - command:
#         - /bin/sh
#         - -c
#         - |
#           id
#           ls -la /data
#           /usr/sbinx/init_directory_structure.sh
#         image: docker.gitea.com/gitea:1.24.6-rootless
#         name: init-directories
# ...

kubectl -n gitea rollout restart deployment gitea

kubectl -n gitea logs gitea-6f4db975f6-l2txr -c init-directories
# uid=1000(git) gid=1000(git) groups=1000(git)
# total 8
# drwxr-xr-x    2 root     root          4096 Feb 12 07:11 .
# drwxr-xr-x    1 root     root          4096 Feb 28 10:19 ..
# mkdir: can't create directory '/data/git/': Permission denied
```

That's expected, by default gitea is running as a `git` user due to it's `securityContext`

```bash
kubectl -n gitea get deploy gitea -o yaml
#         securityContext:
#           runAsUser: 1000
```

Usually kubernetes changes volumeMounts ownership depending on `securityContext`, however it doesn't work on minikube.
We gotta change it manually using an initContainer:

```yaml
initContainers:
- name: fix-volume-permissions
  image: alpine:latest
  command: 
  - sh
  - -c
  - chown -R 1000:1000 /data
  securityContext:
    runAsUser: 0
    runAsGroup: 0
  volumeMounts:
  - mountPath: /data
    name: data
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
