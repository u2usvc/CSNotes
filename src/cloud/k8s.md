# Useful

## fix namespace stuck in Terminating

```bash
kubectl get namespace $NAMESPACE -o json > ns.json

nvim ns.json
# "finalizers": []

kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f ./ns.json
```

# Quickstart with FCOS

## Setting up FCOS config file (Ignition (ign))

```bash
mkdir coreos
cd coreos
ssh-keygen
# Enter file in which to save the key (/home/fuser/home/.ssh/id_ed25519): ./coreos-1.key

nvim fcos.bu

mkpasswd --method=SHA-512 --rounds=4096
```

```yaml
### fcos.bu
variant: fcos
version: 1.4.0
storage:
  files:
    # CRI-O DNF module
    - path: /etc/dnf/modules.d/cri-o.module
      mode: 0644
      overwrite: true
      contents:
        inline: |
          [cri-o]
          name=cri-o
          stream=1.17
          profiles=
          state=enabled
    # YUM repository for kubeadm, kubelet and kubectl
    - path: /etc/yum.repos.d/kubernetes.repo
      mode: 0644
      overwrite: true
      contents:
        inline: |
          [kubernetes]
          name=Kubernetes
          baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
          enabled=1
          gpgcheck=1
          repo_gpgcheck=1
          gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
            https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    # configuring automatic loading of br_netfilter on startup
    - path: /etc/modules-load.d/br_netfilter.conf
      mode: 0644
      overwrite: true
      contents:
        inline: br_netfilter
    # setting kernel parameters required by kubelet
    - path: /etc/sysctl.d/kubernetes.conf
      mode: 0644
      overwrite: true
      contents:
        inline: |
          net.bridge.bridge-nf-call-iptables=1
          net.ipv4.ip_forward=1
passwd: # setting login credentials
  users:
    - name: core
      password_hash: "$6$rounds=4096$s/c6LBNa9Wtc4VFm$2ih.K2uScKz0Ze7rsI0qbqOLRPL18GSNN3JzmeFEUji3Vceo8dPGaNsEjr6REam1F9P5OyjYeJUneFUSWahDu."
```

```bash
sudo podman run --interactive --rm quay.io/coreos/butane:release --pretty --strict < fcos.bu > fcos.ign
```

Now, fcos.ign file should be generated

## Launching VMs

Create a new ./setup.sh bash script

Make sure to specify full paths:

```bash
### setup.sh
#!/bin/sh

IGN_CONFIG=<IGNITION FILE PATH>
IMAGE=<FEDORA COREOS QCOW2 IMAGE PATH>
VM_NAME=node$1
VCPUS=2
RAM_MB=4096
DISK_GB=10
STREAM=stable

chcon --verbose --type svirt_home_t ${IGN_CONFIG}
virt-install --connect="qemu:///system" --name="${VM_NAME}" \
    --vcpus="${VCPUS}" --memory="${RAM_MB}" \
    --os-variant="fedora-coreos-$STREAM" --import --graphics=none \
    --disk="size=${DISK_GB},backing_store=${IMAGE}" \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGN_CONFIG}" 
```

For example:

```bash
#!/bin/sh

IGN_CONFIG=/var/lib/libvirt/images/fcos.ign
IMAGE=/var/lib/libvirt/images/fedora-coreos-42.20250901.3.0-qemu.x86_64-$1.qcow2
VM_NAME=node$1
VCPUS=2
RAM_MB=4096
DISK_GB=10
STREAM=stable

virt-install --connect="qemu:///system" --name="${VM_NAME}" \
  --vcpus="${VCPUS}" --memory="${RAM_MB}" \
  --os-variant="fedora-coreos-$STREAM" --import --graphics=none \
  --disk="size=${DISK_GB},backing_store=${IMAGE}" \
  --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGN_CONFIG}" --connect=qemu:///system
```

```bash
ls -l
# total 5278780
# -rw-------. 1 spil spil        419 Jan 31 16:10 coreos-1.key
# -rw-r--r--. 1 spil spil        111 Jan 31 16:10 coreos-1.key.pub
# -rw-r--r--. 1 spil spil       1543 Jan 31 15:49 fcos.ign
# -rw-r--r--. 1 spil spil 1806696448 Feb  8 09:40 fedora-coreos-41.20250117.3.0-qemu.x86_64-1.qcow2
# -rw-r--r--. 1 spil spil 1806696448 Feb  8 09:41 fedora-coreos-41.20250117.3.0-qemu.x86_64-2.qcow2
# -rw-r--r--. 1 spil spil 1806696448 Feb  8 09:41 fedora-coreos-41.20250117.3.0-qemu.x86_64-3.qcow2
# -rwxr-xr-x. 1 spil spil        538 Feb  8 08:50 setup.sh

cp fedora-coreos-41.20250117.3.0-qemu.x86_64-1.qcow2 fedora-coreos-41.20250117.3.0-qemu.x86_64-2.qcow2
cp fedora-coreos-41.20250117.3.0-qemu.x86_64-1.qcow2 fedora-coreos-41.20250117.3.0-qemu.x86_64-3.qcow2

qemu-img resize fedora-coreos-41.20250117.3.0-qemu.x86_64-1.qcow2 +20G
qemu-img resize fedora-coreos-41.20250117.3.0-qemu.x86_64-2.qcow2 +20G
qemu-img resize fedora-coreos-41.20250117.3.0-qemu.x86_64-3.qcow2 +20G

virsh net-start --network default

sudo mv fedora-coreos-42.20250901.3.0-qemu.x86_64-1* /var/lib/libvirt/images/
sudo chown qemu:qemu /var/lib/libvirt/images/fedora-coreos-42.20250901.3.0-qemu.x86_64-1.qcow2
sudo chown qemu:qemu /var/lib/libvirt/images/fedora-coreos-42.20250901.3.0-qemu.x86_64-2.qcow2
sudo chown qemu:qemu /var/lib/libvirt/images/fedora-coreos-42.20250901.3.0-qemu.x86_64-3.qcow2

sudo cp ./fcos.ign /var/lib/libvirt/images/
sudo chown qemu:qemu /var/lib/libvirt/images/fcos.ign
sudo chcon -t svirt_image_t /var/lib/libvirt/images/fcos.ign

chmod +x setup.sh
./setup.sh 1
./setup.sh 2
./setup.sh 3
```

If the following error appears:

```bash
Ignition: no config provided by user
No SSH authorized keys provided by Ignition or Afterburn
```

then delete the qcow2 image first. Ignition config is only applied during the first boot.

## Configuring VMs

First edit the /etc/hosts file and add the addresses of VMs (addresses will be shown in the output of ./setup.sh script)

``` bash
### /etc/hosts
# k8s
192.168.67.173 coreos-1
192.168.67.54  coreos-2
192.168.67.83  coreos-3
```

then connect via ssh using:

``` bash
ssh -i ./coreos-1.key coreos-1
ssh -i ./coreos-1.key coreos-2
ssh -i ./coreos-1.key coreos-3
```

then on each machine:

``` bash
sudo -i
echo "coreos-1" > /etc/hostname
```

then on CP node:
Ensure kubernetesVersion is compatable with cilium {<https://docs.cilium.io/en/stable/network/kubernetes/compatibility/}>

``` bash
vi /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1

sudo systemctl restart systemd-resolved


cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF


sudo rpm-ostree install kubelet kubeadm kubectl cri-o
```

and the same thing, but the different command on the DP nodes:

``` bash
sudo rpm-ostree install kubelet kubeadm cri-o
```

After the reboot, log in to all the nodes again and start CRI-O and kubelet using

``` bash
sudo systemctl enable --now crio kubelet
systemctl reboot
```

Create a clusterconfig.yml on the control plane just like the following: (change the k8s version)
Ensure kubernetesVersion is compatable with cilium [https://docs.cilium.io/en/stable/network/kubernetes/compatibility]

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
    kind: ClusterConfiguration
kubernetesVersion: v1.30.7
controllerManager:
extraArgs: # specify a R/W directory for FlexVolumes (cluster won't work without this even though we use PVs)
flex-volume-plugin-dir: "/etc/kubernetes/kubelet-plugins/volume/exec"
networking: # pod subnet definition
podSubnet: 10.244.0.0/16
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
```

``` bash
### NUMBER OF VCPUS
sudo kubeadm init --config ./clusterconfig.yml
# Your Kubernetes control-plane has initialized successfully!
# 
# To start using your cluster, you need to run the following as a regular user:
# 
#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config
# 
# Alternatively, if you are the root user, you can run:
# 
#   export KUBECONFIG=/etc/kubernetes/admin.conf
# 
# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/
# 
# Then you can join any number of worker nodes by running the following on each as root:
# 
# kubeadm join 192.168.67.72:6443 --token ds54i4.t33jmdnzs5wcl5yd \
#         --discovery-token-ca-cert-hash sha256:34998b9ab2346add1db8192c614cbbbc9eece163db7b7d4c72ddaa822700db7d

echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' > ~/.bashrc
kubectl get nodes
# ensure server version is correct
kubectl version
```

then on all DP nodes:

``` bash
sudo -i
# the following is the command you got from `kubeadm init` output
kubeadm join 192.168.67.173:6443 --token wuwvjt.95mxeb5i4tdwihzx --discovery-token-ca-cert-hash sha256:ddb8836e174babd5165ebfa7ddd88f9d5afa7d3e064b42a2b7ea1c8b3be6bcf7
# [preflight] Running pre-flight checks
# [preflight] Reading configuration from the cluster...
# [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
# [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
# [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
# [kubelet-start] Starting the kubelet
# [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...
# 
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.
# 
# Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
echo 'export KUBECONFIG=/etc/kubernetes/kubelet.conf' > ~/.bashrc
kubectl get nodes
```

Setup Cilium

1. proceed to execute the following commands on CP node
2. Check version compatibility

``` bash
rpm-ostree install helm
systemctl reboot
helm repo add cilium https://helm.cilium.io
helm repo update
helm install cilium cilium/cilium --version 1.17.0 --namespace kube-system


cat <<EOF | sudo tee ./cilium.sh
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
EOF

chmod +x ./cilium.sh


cilium install

# test
cilium status --wait
cilium connectivity test
```

The cluster is up and ready now

## testing the cluster by creating the nginx deployment and service for it

You can create a test deployment of three NGINX instances with:

``` bash
kubectl create deployment test --image nginx --replicas 3
```

and a Service to be able to access it externally (in a file called testsvc.yml, for example):

```yaml
apiVersion: v1
kind: Service
metadata:
name: testsvc
spec:
type: NodePort
selector:
app: test
ports:
- port: 80
nodePort: 30001
```

Apply with `kubectl create -f testsvc.yml` and test that everything works correctly by navigating to `http://coreos-1:30001` with browser/curl.

## Installing Kyverno

``` bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```
