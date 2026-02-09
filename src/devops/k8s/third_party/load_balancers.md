# Load Balancers

## MetalLB

### Setup

Each address from the pool is gonna be assigned to the LoadBalancer.

```bash
helm repo add metallb https://metallb.github.io/metallb

nvim metallb-config.yaml
# apiVersion: metallb.io/v1beta1
# kind: IPAddressPool
# metadata:
#   name: default-pool
#   namespace: metallb-system
# spec:
#   addresses:
#     - 192.168.88.242-192.168.88.244
# ---
# apiVersion: metallb.io/v1beta1
# kind: L2Advertisement
# metadata:
#   name: default
#   namespace: metallb-system

kubectl apply -f metallb-config.yaml

# we can now access the service externally
curl http://gitea.aperture.ad

# label metallb-system ns with privileged to allow metallb-speaker pods
kubectl label --overwrite namespace metallb-system \
pod-security.kubernetes.io/enforce=privileged \
pod-security.kubernetes.io/enforce-version=latest
```
