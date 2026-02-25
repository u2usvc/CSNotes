# FHRP

## VRRP

### MT ROS setup

1. vrid is an ID of a VIRTUAL router, each needs to have a unique ID.
2. `authentication=none` is default (TODO) non-none values are only supported if version != 3
3. `priority=100` is default (Higher priority wins!)
4. Upon entering a backup state the IP address assigned to VRRP interface SHOULD become Invalid, this is expected!

```bash
#    |----|          |----|  
#    | R1 |          | R2 |
#    |----| ether2   |----|
#       |  \__    __/  | <------ ether1
#       |     \__/     |
#    |----|___/  \___|----|      
#    | S1 |          | S2 |
#    |----|==========|----|


### R2:
# OPT: real iface address:
/ip address add address=192.168.1.1/24 interface=ether1

# can be assigned on VLAN interface (interface=vlan-20)
/interface vrrp add name=vrrp-1 interface=ether1 vrid=1 priority=250
/interface vrrp add name=vrrp-1 interface=ether1 vrid=1 priority=250 authentication=ah password=somepass1 version=2
# OPT: if you have multiple gateways on downstream switches:
/interface vrrp add name=vrrp-2 interface=ether1 vrid=2 priority=240 authentication=ah password=somepass2 version=2
# OPT: if you have multiple downstream nodes interconnected with VRRP routers in mesh for redundancy:
# priorities should be set to higher values on a master router. vrid should be the same on all interfaces that have
# the same VIP address
/interface vrrp add name=vrrp-3 interface=ether2 vrid=1 priority=230 authentication=ah password=somepass1 version=2

# virtual addresses (HAVE TO BE /32):
# you CAN assign multiple ip addresses to a single VRRP interface and single VRID
/ip address add address=192.168.1.101/32 interface=vrrp-1
# OPT: if you have multiple gateways on downstream switches:
/ip address add address=10.10.1.102/32 interface=vrrp-2
# OPT: if you have multiple downstream nodes interconnected with VRRP routers in mesh for redundancy:
/ip address add address=192.168.1.101/32 interface=vrrp-3
```
