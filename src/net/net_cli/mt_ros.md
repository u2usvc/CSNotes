# MikroTik RouterOS

## BFD

```bash
# enable BFD on interfaces (you can just use interfaces=all)
# `min-tx/min-rx = 1` means 1 second interval
/routing/bfd/configuration/add interfaces=ether5,ether6,ether7,ether8 min-tx=1 min-rx=1
# then in OSPF/BGP/whatever config set use-bfd=yes on an interface so that it will send BFD hello packets
```

## DoH

```bash
# set the cloudflare server ("servers" is to resolve the DoH server itself, use-doh-server is a DoH server address)
# after DoH server address is resolved all other DNS requests will be made via DoH
/ip/dns/set verify-doh-cert=yes allow-remote-requests=yes doh-max-concurent-queries=100 doh-max-server-connections=20 doh-timeout=6s servers=1.1.1.1 use-doh-server=https://cloudflare-dns.com/dns-query

# fetch the downloaded cert chain
/tool/fetch url=http://192.168.60.1:9595/one-one-one-chain.pem
/file/print

/certificate/import file-name=one-one-one-chain.pem
# certificates-imported: 3
```

## MAC TELNET

```bash
/ip/service/enable numbers=telnet
/interfaces/print

sudo apt install mactelnet-client
mactelnet $MAC
```

## OSPF

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

## VLAN

frame-types:

```bash
# only tagged traffic will be send out (set this on trunk ports) 
# (if you send it on bridge it means that only tagged traffic will be send OUT OF THE TRUNK PORT)
# be carefull setting this because you will not be able to send packets from the router itself out of trunk ports
frame-types=admit-only-vlan-tagged

# only untagged traffic will be send out (set this on access ports)
frame-types=admit-only-untagged-and-priority-tagged
```

VLAN switching:

```bash
# {https://forum.mikrotik.com/viewtopic.php?t=180903}
# add bridge for vlan switching (a single bridge should be used generaly (if multiple bridges are used - bringing will not be able to be hardware-offloaded (i.e. more CPU load)))
/interface/bridge/add name=vlan-br-1 vlan-filtering=yes # WARNING!!! if you're connected to router remotely FIRST OMIT vlan-filtering option, since it will break the connection
# priority=0x5000 - possible if you wanna adjust STP (or MSTP/RSTP) priority value (the lower the priority the more chance it'll become the root bridge)
# frame-types=admit-only-vlan-tagged - POSSIBLE, BUT DANGEROUS

# attach physical interface to a virtual bridge interface (trunk). Don't forget to add appropriate bridge VLAN table entries
/interface/bridge/port/add bridge=vlan-br-1 interface=ether1
# frame-types=admit-only-vlan-tagged - POSSIBLE, BUT DANGEROUS (not required)

# attach physical interface to a virtual bridge interface (access). Don't forget to add appropriate bridge VLAN table entries
/interface/bridge/port/add bridge=vlan-br-1 interface=ether2 pvid=20
/interface/bridge/port/add bridge=vlan-br-1 interface=ether3 pvid=30
# frame-types=admit-only-untagged-and-priority-tagged - POSSIBLE, BUT DANGEROUS (not required)

# add a bridge VLAN table entry for each bridge port (if multiple interfaces are connected to ONE VLAN specify them), untagged interfaces are ones that will be linked with a VLAN itself
# and set /ip/dns/set allow-remote-requests=yes
# REPEAT that sequence on each switch that stands in a way
/interface/bridge/vlan/add bridge=vlan-br-1 tagged=ether1,vlan-br-1 untagged=ether2 vlan-ids=20
/interface/bridge/vlan/add bridge=vlan-br-1 tagged=ether1,vlan-br-1 untagged=ether3,ether4 vlan-ids=30

# Add a vlan interface (enable VLAN tagging for a particular VLAN (10) on a specific interface (ether2)) (don't forget to add an address to it and a coresponding entry in a bridge-VLAN table afterwards)
/interface/vlan/add name=vlan-20 vlan-id=20 interface=vlan-br-1
/interface/vlan/add name=vlan-30 vlan-id=30 interface=vlan-br-1
# add upstream address for clients
/ip/address/add address=10.10.20.1/24 interface=vlan-20 # don't forget to write different addresses on second router for VRRP
/ip/address/add address=10.10.30.1/24 interface=vlan-30


# on each router / managed switch that stands in a way enable NAT masquerade
/ip/firewall/nat/add chain=srcnat out-interface=vlan-br-1 action=masquerade


# afterwards you can create a dhcp server (interface=vlanX)
ip/pool/add name=vlan-20-pool ranges=192.168.20.100-192.168.20.200
/ip/dhcp-server/add interface=vlan-20 address-pool=vlan20-pool name=vlan-20-dhcp
/ip/dhcp-server/network/add address=192.168.20.0/24 dns-server=192.168.20.1 gateway=192.168.20.1 netmask=24
ip/pool/add name=vlan-30-pool ranges=192.168.30.100-192.168.30.200
/ip/dhcp-server/add interface=vlan-30 address-pool=vlan30-pool name=vlan-30-dhcp
/ip/dhcp-server/network/add address=192.168.30.0/24 dns-server=192.168.30.1 gateway=192.168.30.1 netmask=24

## if you're configuring VXLAN - clients should already be able to reach each other on both sides of VXLAN
## if you want your routers to be reachable, on both routers assign single-subnet address ON A BRIDGE
# R1
/ip/address/add address=172.16.102.1/24 interface=vlan-br-1
# R2
/ip/address/add address=172.16.102.2/24 interface=vlan-br-1
```

OPTIONAL: add VRRP

```bash
### MIRROR THIS CONFIGURATION ON A SECOND ROUTER, BUT WITH DIFFERENT PRIORITY
/interface vrrp add name=vrrp-m-20 interface=vlan-20 vrid=20 priority=200
/interface vrrp add name=vrrp-m-30 interface=vlan-30 vrid=30 priority=200

# pay attention: addresses should be reachable from clients on VLAN
# This SHOULD be /32 !!!
/ip address add address=192.168.20.3/32 interface=vrrp-m-20
/ip address add address=192.168.30.3/32 interface=vrrp-m-30

/ip/dhcp-server/network/add address=192.168.20.0/24 gateway=192.168.20.3 dns-server=192.168.20.3
/ip/dhcp-server/network/add address=192.168.30.0/24 gateway=192.168.30.3 dns-server=192.168.30.3
```

OPTIONAL: VLAN isolation

```bash
add action=drop chain=forward dst-address=192.168.55.0/27 src-address=192.168.80.0/24
```

## VPLS

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

## VRRP

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

## VXLAN

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

## WG tunnel to LAN

```bash
/interface/wireguard/add listen-port=13231 name=wireguard1
# this is the subnet that the client will "tunnel out of"
# each client must have allowed-address from 192.168.100.1/24
/ip/address/add address=192.168.100.1/24 interface=wireguard1

# [admin@home] > /interface wireguard print 
#     Flags: X - disabled; R - running 
#      0  R name="wireguard1" mtu=1420 listen-port=11111 private-key="SERVER_PRIVATE_KEY"
#           public-key="SERVER_PUBLIC_KEY"

/interface/wireguard/peers/add allowed-address=192.168.100.2/32 interface=wireguard1 public-key="CLIENT_PUBLIC_KEY" preshared-key="PEER_PSK"

/ip/firewall/filter/add action=accept chain=input comment="allow WireGuard" dst-port=11111 protocol=udp place-before=1
/interface/list/member/add interface=wireguard1 list=LAN

/ip/firewall/nat/add action=src-nat chain=srcnat src-address=192.168.100.0/24 to-addresses=192.168.88.1
```

Connect from debian:

```bash
wg genkey | sudo tee /etc/wireguard/private.key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
wg genkey | sudo tee /etc/wireguard/preshared.key

sudo nvim /etc/wireguard/wg0.conf
# [Interface]
# PrivateKey = CLIENT_PUBLIC_KEY
# # this clients address on the destination device
# Address = 192.168.100.2/32
# DNS = 192.168.100.1
# 
# [Peer]
# PresharedKey = PEER_PSK
# PublicKey = SERVER_PUBLIC_KEY
# # defines which dst-address will go through the tunnel
# # example: AllowedIPs = 0.0.0.0/0
# AllowedIPs = 192.168.100.0/24, 192.168.88.0/24
# Endpoint = xxx.xxx.xxx.xxx:11111

# or nm-connection-editor
sudo nmcli connection import type wireguard file /etc/wireguard/wg0.conf
nmcli connection
# or using wg-quick
wg-quick up wg0
```

## flash

```bash
sudo nvim /etc/network/interfaces
# auto enx00e04c36350d
# iface enx00e04c36350d inet static
#     address 192.168.88.2/24
#     gateway 192.168.2.1

sudo systemctl restart networking

sudo ./netinstall-cli -r -a 192.168.88.1 mt/routeros-7.20-arm64.npk mt/container-7.20-arm64.npk mt/user-manager-7.20-arm64.npk mt/wifi-qcom-7.20-arm64.npk

# connect to WAN port

# now you can proceed to boot the device into EtherBoot mode (poweron the device while holding reset button until it stops blinking)
```

## ssh by key

```bash
/file/add name=mtusr.pub contents="ssh-ed25519 thisismypublickey usr@debian" type=file
/user ssh-keys import public-key-file=mtusr.pub user=mtusr
/ip ssh set strong-crypto=yes
/ip ssh set always-allow-password-login=no
```

## update static DNS entries from DHCP

```bash
/system/script/add name=update-dns-from-dhcp policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive source="
:local domain ".aperture.ad";
:local leases [/ip dhcp-server lease find dynamic=yes];

:foreach i in=[/ip dns static find where name~$domain] do={
    /ip dns static remove $i;
}

:foreach i in=$leases do={
    :local hostname [/ip dhcp-server lease get $i host-name];
    :local address [/ip dhcp-server lease get $i address];

    :if ([:len $hostname] > 0) do={
        :local fqdn ($hostname . $domain);
        /ip dns static add name=$fqdn address=$address ttl=5m comment="From DHCP lease";
    }
}
"

/system scheduler add name=update-dns-from-dhcp interval=5m on-event="/system script run update-dns-from-dhcp"
```
