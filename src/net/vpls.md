# VPLS

## MT ROS setup

```bash
# R1 (IP : 10.0.0.1)
/interface/bridge/add name=vpls-tun-1
# vpls-id is just a tunnel identifier, you can use whatever, but people usually use their AS number
# note the X:X format !!!
/interface/vpls/add name=vpls-tun-4-3 vpls-id=1:102 peer=10.0.0.2

## join route-to-customer and vpls-tunnel together using a bridge
#  add vpls tunnel to bridge
/interface/bridge/port/add interface=vpls-tun-4-3 bridge=vpls-tun-1
# add customer-facing interface to a bridge
/interface/bridge/port/add interface=ether4 bridge=vpls-tun-1


# R2 (IP : 10.0.0.2)
/interface/bridge/add name=vpls-tun-1
/interface/vpls/add name=vpls-tun-3-4 vpls-id=1:102 peer=10.0.0.2
/interface/bridge/port/add interface=vpls-tun-4-3 bridge=vpls-tun-1
/interface/bridge/port/add interface=ether4 bridge=vpls-tun-1

# check
/interface/vpls/monitor


# clients now can set an address on upstream interfaces (that're connected to your routers) and communicate with each other on the same subnet (ofc you do NOT need to set any addresses on your routers)
```
