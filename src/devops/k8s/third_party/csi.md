# CSI

## Rook

### Setup

Install Rook:

```bash
git clone --single-branch --branch release-1.18 https://github.com/rook/rook.git
cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f csi-operator.yaml -f operator.yaml
kubectl create -f cluster.yaml
```

```bash
# list api-resources to ensure cephcluster is present
kubectl api-resources
# cephclusters        ceph        ceph.rook.io/v1          true         CephCluster

kubectl get cephclusters -A
# NAMESPACE   NAME        DATADIRHOSTPATH
# rook-ceph   rook-ceph   /var/lib/rook

# OPTIONALLY
# after TLDR deployment edit the amount of mons to fit your cluster (3 recommended)
# {https://rook.io/docs/rook/latest/CRDs/Cluster/ceph-cluster-crd/#ceph-config}
kubectl edit -n rook-ceph cephcluster rook-ceph
# spec:
#   mon:
#     count: 2
#   cephConfig:
#     global:
#       osd_pool_default_size: "2"

# label the rook-ceph namespace with pod-security.kubernetes.io/enforce=privileged label
# otherwise pods won't deploy due to violating PodSecurity
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged --overwrite

# ensure all rook-ceph resources are ready
watch kubectl -n rook-ceph get pods

# ensure HEALTH_OK
kubectl rook-ceph ceph status
```

Now you can choose from 3 storage options: [https://rook.io/docs/rook/latest/Getting-Started/quickstart/#storage](https://rook.io/docs/rook/latest/Getting-Started/quickstart/#storage)
I will go with Block storage:

First copy the manifest from [https://rook.io/docs/rook/latest/Storage-Configuration/Block-Storage-RBD/block-storage/#provision-storage](https://rook.io/docs/rook/latest/Storage-Configuration/Block-Storage-RBD/block-storage/#provision-storage) and save it to `storageclass.yaml` file.

```bash
# adjust replication size if needed
nvim storageclass.yaml
# spec:
#   failureDomain: host
#   replicated:
#     size: 2

# create StorageClass and CephBlockPool
kubectl create -f storageclass.yaml
```
