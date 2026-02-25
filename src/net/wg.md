# Wireguard

## WG tunnel to LAN on MT ROS & debian

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
