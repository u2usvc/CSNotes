# DRP

## BFD

### MT ROS setup

```bash
# enable BFD on interfaces (you can just use interfaces=all)
# `min-tx/min-rx = 1` means 1 second interval
/routing/bfd/configuration/add interfaces=ether5,ether6,ether7,ether8 min-tx=1 min-rx=1
# then in OSPF/BGP/whatever config set use-bfd=yes on an interface so that it will send BFD hello packets
```

## OSPF

### MT ROS setup

```bash
# create a loopback for fault tolerance
/interface/bridge/add name=Lo0

# first assign IP addresses
/ip/address/add interface=Lo0 address=10.0.0.4/32
/ip address add address=192.168.0.3/24 interface=ether1
/ip address add address=192.168.1.3/24 interface=ether2

/routing ospf instance add name=ospfv2-inst version=2 router-id=10.0.0.4
# area-id is usually, 0.0.0.0, 1.1.1.1, 2.2.2.2, etc.
/routing ospf area add name=ospfv2-a0 area-id=0.0.0.0 instance=ospfv2-inst

### if interfaces are not specified ROS will detect automatically!
### use-bfd can be ommited! if it's not - see *BFD for bfd configuration
/routing ospf interface-template add networks=192.168.0.0/24,192.168.1.0/24,10.0.0.4/32 area=ospfv2-a0 interfaces=ether3,bond-9-2,Lo0 use-bfd=yes

# allow ospf traffic (is not needed if no rules are present)
/ip firewall filter add action=accept chain=input protocol=ospf
```
