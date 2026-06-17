# Hypervisors

## Proxmox

### persistently reach proxmox VMs behind virtual OPNsense from an outer LAN

OPNsense is deployed on Proxmox as a VM with an address of `192.168.88.165`. IP address of proxmox is `192.168.88.69`.
Interface layout is as follows: `MT ROS === host <=== Cisco switch ===> Proxmox_enp3s0 === vmbr0 === OPNsense === vmbr1 === LAN_host`
LAN_host address is `192.168.1.145`, which is statically.
DHCP server for `192.168.88.0/24` subnet is running on Mikrotik RouterOS (MT ROS).

The idea is to be able to access `192.168.1.145` from `192.168.88.250` (or any machine on physical LAN) seamlessly.

Automatic host configuration via DHCP option 121 (change the value)

```bash
### ON MIKROTIK
# this option will inject additional route to mikrotik LAN client (192.168.88.250) in order for it to know where to send packets dedicated for `192.168.1.0/24`
# $VALUE == 192.168.1.0/24 via 192.168.88.165
/ip/dhcp-server/option/add name=route20 code=121 value=$VALUE
/ip/dhcp-server/network/set numbers=0 dhcp-option=route20
# this will tell the mikrotik to route packets to OPNsense if they are dedicated to `192.168.1.0/24`
/ip/route/add dst-address=192.168.1.0/24 gateway=192.168.88.165
# check on 192.168.88.250 using `ip r` or `route print`
```

Manual

```bash
sudo ip route add 192.168.1.0/24 via 192.168.88.165
```

Automatic LAN_host configuration via DHCP option 121 (change the value)

```bash
# this option will inject additional route to the target (192.168.1.145 LAN_host machine) in order for it to know where to send packets dedicated for `192.168.88.0/24`
# 0x18C0A858C0A80101 == 192.168.88.0/24 via 192.168.1.1
Services/Dnsmasq_DHCPv4/General/DHCP_options/18:C0:A8:58:C0:A8:01:01*
```

Manual

```bash
route ADD -p 192.168.88.0 MASK 255.255.255.0 192.168.1.1
```

Via GPO

```
Computer Configuration > Preferences > Windows Settings > Registry > New > Registry Item

- Action: Create
- Hive: HKEY_LOCAL_MACHINE
- Key Path: SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\PersistentRoutes
- Value name: 192.168.88.0,255.255.255.0,192.168.1.1,1
- Value type: REG_SZ
- Value data: (empty)
```

OPNsense config

```bash
# on OPNsense (OPNsense does route between all interfaces by default. What you need is a firewall rule to permit the traffic to pass.)
Interfaces/WAN/Block_private_networks/0
Firewall/Rules/WAN/allow_all*
Firewall/Rules/LAN2/allow_all*

# do not forget to apply all changes
```


While setting this thing up I've experienced an issue where the OPNsense WAN to LAN traffic was not going through.
After inspecting with wireshark I discovered the following flow:

Debian (.1.145) did receive the traffic from my host (.88.250), but it did only receive the SYN. SYN,ACK that debian was sending was not :

1) 88.250 > 1.145 TCP SYN
2) 1.145 > 88.250 TCP SYN,ACK
3) 1.145 > 88.250 TCP SYN,ACK
4) 88.250 > 1.145 TCP Retransmission
5) 1.145 > 88.250 TCP Retransmission
6) ...

The host machine itself was confirmed to not receive SYN,ACK

By observing the traffic on proxmox enp3s0 using tcpdump i've determined that the issue was in the SYN,ACK packet sent from the OPNsense (`bc:24:11:1f:fc:65 > f4:1e:57:d0:0a:f6, ethertype IPv4 (0x0800), length 74: 192.168.1.145.9595 > 192.168.88.250.56312: Flags [S.], seq 3609614974, ack 1961682388, win 65160, options [mss 1460,sackOK,TS val 1330034951 ecr 3932918869,nop,wscale 9], length 0`)
The `f4:1e:57:d0:0a:f6` is not a MAC address of `192.168.88.250`, it is the MAC address of `192.168.88.1`, because the default gateway for `192.168.88.0/24` is `192.168.88.1` on OPNsense side. When this SYN,ACK arrives to Cisco, it forwards it to MT ROS.
In order to allow MT ROS to forward this packet back we gotta enable invalid connection state, since SYN packet never reached MT ROS:

```bash
/ip firewall filter add chain=forward src-address=192.168.1.0/24 dst-address=192.168.88.0/24 action=accept place-before=0
```
