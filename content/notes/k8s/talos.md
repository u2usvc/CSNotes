# Talos

## Quickstart

Install talosctl on management machine (e.g. debian)

```bash
curl -sL https://talos.dev/install | sh
```

Create a custom ISO with all defaults except ticking "qemu-guest-agent" extention
[https://factory.talos.dev/](https://factory.talos.dev/) - copy ISO and "Initial Installation" strings

download the iso within proxmox

boot the VM with all default parameters except for CPU (2 cores) and RAM (8Gb). Attach virtual hard drives to DP nodes.

```bash
export CONTROL_PLANE_IP=192.168.1.189
nvim patch.yaml
# cluster:
#   network:
#     cni:
#       name: none

# paste the "Initial installation" link
talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image factory.talos.dev/metal-installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.11.2 --config-patch @patch.yaml
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file _out/controlplane.yaml
```

Repeat the VM creation process for each DP node

```bash
export WORKER_IP=192.168.1.109
talosctl apply-config --insecure --nodes $WORKER_IP --file _out/worker.yaml
```

Run the following commands:

```bash
export TALOSCONFIG="_out/talosconfig"
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP
talosctl bootstrap --nodes $CONTROL_PLANE_IP

# retrieve kubeconfig to current directory
talosctl kubeconfig .

# test the cluster
kubectl --kubeconfig=./kubeconfig get nodes

# create a link to kubeconfig so that we don't have to
# specify the path to it all the time
ln -s ~/proxmox/kubeconfig ~/.kube/config
```
