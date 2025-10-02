# Libvirt networking

## bridge a libvirt guest domain to physical LAN

Scenario:

- DHCP server is running on physical router
- debian host running libvirtd (host's address == 192.168.1.69)
- debian libvirt/qemu VM (VM's address == 192.168.1.100)

```bash
sudo apt install bridge-utils

# on the host
sudo vim /etc/network/interfaces
# auto br0
# iface br0 inet static
#     address 192.168.1.69/24
#     gateway 192.168.1.1
#     bridge_ports enp3s0
#     bridge_stp off
#     bridge_fd 0
#     bridge_maxwait 0

# on the VM
sudo vim /etc/network/interfaces
# auto enp1s0
# iface enp1s0 inet static
#     address 192.168.1.100/24
#     gateway 192.168.1.1

# VM (domain) definition
virsh edit dc-1
# <interface type='bridge'>
#   <source bridge='br0'/>
#   <model type='virtio'/>
# </interface>

# on the host
sudo systemctl restart systemd-networkd

# ensure correct interface layout on host
ip a
# 2: enp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
#     link/ether 74:56:3c:91:53:35 brd ff:ff:ff:ff:ff:ff
#     altname enx74563c915335
# 3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
#     link/ether ee:58:46:54:ea:9c brd ff:ff:ff:ff:ff:ff
#     inet 192.168.1.69/24 brd 192.168.1.255 scope global br0
#        valid_lft forever preferred_lft forever
#     inet6 fe80::ec58:46ff:fe54:ea9c/64 scope link proto kernel_ll
#        valid_lft forever preferred_lft forever

# on VM
ip a
# 2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
#     link/ether 52:54:00:eb:a8:c2 brd ff:ff:ff:ff:ff:ff
#     altname enx525400eba8c2
#     inet 192.168.1.100/24 brd 192.168.1.255 scope global enp1s0
#        valid_lft forever preferred_lft forever
#     inet6 fe80::5054:ff:feeb:a8c2/64 scope link proto kernel_ll
#        valid_lft forever preferred_lft forever
```

## create an isolated network

```xml
<network>
  <name>fcos_k8s_lab</name>
  <uuid>280c4dd6-e5e4-478b-aa71-6d7aaa326eae</uuid>
  <forward mode='nat'/>
  <bridge name='k8sbr0' stp='on' delay='0'/>
  <mac address='52:54:00:fd:d7:c7'/>
  <domain name='k8s.local'/>
  <dns enable='yes'>
    <forwarder addr='1.1.1.1'/>
  </dns>
  <ip family='ipv4' address='192.168.122.1' prefix='24'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
      <!-- <host mac='50:73:0F:31:81:E1' name='coreos01' ip='192.168.122.101'/> -->
      <!-- <host mac='50:73:0F:31:81:E2' name='coreos02' ip='192.168.122.102'/> -->
      <!-- <host mac='50:73:0F:31:81:F1' name='coreos03' ip='192.168.122.103'/> -->
      <!-- <host mac='50:73:0F:31:81:F2' name='coreos04' ip='192.168.122.104'/> -->
    </dhcp>
  </ip>
</network>
```

## attach multiple interfaces to 1 host

```bash
### ATTACH A BRIDGE TO HOST/ANOTHER VM
# this will create the corresponding virtual NIC on a VM
# get rid of --persistent if you just want a temporary interface
# virbr15 is the VNI for the network you wanna attach. You can create it manually using `ip`
virsh attach-interface --type bridge --source virbr15 --model virtio --domain mt-chr-1 --persistent

### ATTACH TO A NETWORK
# this network needs to be created with libvirt as a 'network'
virsh attach-interface --type network --source ad_lab --model virtio --domain mt-chr-1 --persistent
```

## basic network definition template

You may use `virsh net-define /usr/share/libvirt/networks/default.xml` to define an initial network configuration.

```xml
<network>
  <name>advenv_net</name>
<!-- ensure UUID is valid -->
  <uuid>dcd932a5-6ba1-4d46-b56e-2c7ec8722e58</uuid>
  <forward mode='nat'/>
<!-- this bridge interface will be created automatically by libvirt  -->
<!-- and all virtual tap/tun VM's interfaces will be attached to it also automatically -->
  <bridge name='virbr1' stp='on' delay='0'/>
<!-- ensure MAC is valid -->
  <mac address='52:54:00:ff:a0:64'/>
  <domain name='advenv.local'/>
  <dns enable='no'/>
<!-- CIDR for a bridge interface -->
  <ip family='ipv4' address='10.0.100.1' prefix='24'>
<!-- DHCP rules -->
    <dhcp>
      <range start='10.0.100.2' end='10.0.100.254'/>
<!-- host mapping is OPTIONAL -->
      <host mac='52:54:00:52:D8:3A' name='dc-2' ip='10.0.100.2'/>
      <host mac='b0:ee:79:6d:50:3f' name='debian1' ip='10.0.100.15'/>
      <host mac='aa:df:3a:fe:eb:a4' name='debian2' ip='10.0.100.20'/>
    </dhcp>
  </ip>
</network>
```

## fix NAT issues (nftables)

```bash
cat /etc/default/ufw | grep DEFAULT_FORWARD_POLICY
# DEFAULT_FORWARD_POLICY="DROP" -------> ACCEPT
DEFAULT_FORWARD_POLICY="ACCEPT"

ufw reload
```

```bash
sudo grep 'firewall_backend' /etc/libvirt/network.conf
# firewall_backend = "nftables"

# 1) attempt to purge nftables ruleset
sudo nft flush ruleset

# 2.1) ensure firewalld (or whatever frontend you are using) repopulates nft ruleset
sudo systemctl restart firewalld
# 2.2) ensure libvirtd is started before libvirt_network is started
sudo systemctl restart libvirtd

# 3) ensure nftables ruleset is repopulated by firewalld
sudo nft list ruleset

# 4) ensure kernel forwarding is enabled
sysctl net.ipv4.ip_forward
# net.ipv4.ip_forward = 1

# 5) start all necessary resources
virsh net-start --network default
virsh start debian-tmp-1
virsh console --domain debian-tmp-1
# ping 1.1.1.1
```

## fix libvirt dnsmasq address already in use issue

```bash
sudo rc-update del dnsmasq
sudo rc-service dnsmasq stop
```

OR

```bash
# make dnsmasq listen on specific interface
interface=eth0
# OR make dnsmasq listen on specific address
listen-address=192.168.0.1

# AND uncomment this line
bind-interfaces
```
