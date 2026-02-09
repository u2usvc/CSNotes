# CRI

## CRI-O

### Execution

#### run command against crio container

```bash
# list running containers
crictl ps

# run command on a container
crictl exec -it $CONTAINER_ID /bin/bash
```

## Cilium

### Installation

Nodes will be in the NotReady status, because there is no CNI.

```bash
# cilium install --namespace kube-system will result in an `unable to apply caps: operation not permitted`
# error: {https://docs.siderolabs.com/talos/v1.11/learn-more/process-capabilities};
# {https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium};
# append cni.exclusive=false for integration with istio (see {https://istio.io/latest/docs/ambient/install/platform-prerequisites/#cilium})
cilium install --namespace kube-system \
--set kubeProxyReplacement=false \
--set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
--set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
--set cgroup.autoMount.enabled=false \
--set cgroup.hostRoot=/sys/fs/cgroup \
--set cni.exclusive=false

cilium status --wait
# wait until it's OK
```
