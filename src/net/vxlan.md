# VXLAN

## MT ROS setup

```bash
#### customer routert
### on customer's side you CAN also configure VLANs to separate traffic

### R1 (IP : 10.0.0.1)
/interface vxlan add name=vxlan-vni-102 vni=102
/interface vxlan vteps add interface=vxlan-vni-102 remote-ip=10.0.0.2
/interface/bridge/add name=vxlan-br-102
# ether12 goes to customer's router
/interface/bridge/port/add interface=ether12 bridge=vxlan-br-102
/interface/bridge/port/add interface=vxlan-vni-102 bridge=vxlan-br-102

### R2 (IP : 10.0.0.2)
/interface vxlan add name=vxlan-vni-102 vni=102
/interface vxlan vteps add interface=vxlan-vni-102 remote-ip=10.0.0.1
/interface/bridge/add name=vxlan-br-102
# ether12 goes to customer's router
/interface/bridge/port/add interface=ether12 bridge=vxlan-br-102
/interface/bridge/port/add interface=vxlan-vni-102 bridge=vxlan-br-102
```
