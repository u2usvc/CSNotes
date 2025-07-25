# Libvirt/QEMU
## QEMU
### disk creation
```bash
# Emulated disk space management (also can shrink, resize an image or store overlay images (see arch-wiki))
qemu-img create -f raw image_file 4G              # Create a raw disk space (`-f qcow2` to utilize dinamically-allocated format)
qemu-img resize disk_image +10G                   # Resize an image (if contains NTFS backup it first)
qemu-img convert -f raw -O qcow2 -o nocow=on input.iso output.qcow2  # specify -o nocow=on if you use btrfs
```

### windows
```bash
#!/bin/sh

# sudo qemu-system-x86_64 -drive file=win2016-cli.qcow2,format=qcow2 -m 2G -cpu host -enable-kvm -nic user -vga qxl -spice port=5925,disable-ticketing=on -usbdevice tablet -daemonize


SPICE_PORT=5924
qemu-system-x86_64 -enable-kvm -daemonize \
    -cpu host \
    -drive file=win10-gui.qcow2,if=virtio \
    -nic user \
    -m 8G \
    -bios /usr/share/edk2-ovmf/OVMF_CODE.fd. \
    -vga qxl \
    -spice port=${SPICE_PORT},disable-ticketing=on \
    -usbdevice tablet \
    -device virtio-serial \
    -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    "$@"
exec spicy --title Windows 127.0.0.1 -p ${SPICE_PORT}

# drive: aio=native,cache.direct=on
# cpu:   hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time
# -net nic -net user,hostname=windowsvm    --->  -nic user
```

## Libvirt
### Prerequisites
```bash
usermod -aG libvirt myuser

rc-service libvirtd start
# OR 
systemctl start libvirtd
```

### virt-install
```bash
# define domain from iso (create a qcow2 image first)
qemu-img create -f qcow2 debian-1.qcow2 10G
virt-install --name debian-test-2 --memory 1000 --vcpus 2 --osinfo debian12 --disk path=./debian12-1.qcow2,format=qcow2 --cdrom ~/Downloads/debian-12.5.0-amd64-netinst.iso --network network=default

# import an already existing qcow2 image
virt-install --name debian-test-2 --memory 1000 --vcpus 2 --osinfo debian12 --disk path=./debian12-1.qcow2,format=qcow2 --import

# query all available osinfo types
virt-install --osinfo list
```

### MT-CHR installation
```bash
# unarchive
unzip ~/Downloads/chr-7.16.1.vmdk.zip
# convert to qcow2
qemu-img convert -f vmdk -O qcow2 chr-7.16.1.vmdk chr-7.16.1.qcow2
# boot from it (note the --import parameter, this tells qemu to use --disk as a boot drive)
virt-install --name=mt-chr-1 --vcpus=1 --memory=512 --disk path=./chr-7.16.1.qcow2,format=qcow2 --network=network:suricata_sniff --osinfo debian12 --import
```

### resize qcow2 partition
```bash
virt-resize --expand /dev/sda4 fcos-1.qcow2 fcos-2.qcow2
```

### `emulator does not support machine type` error
```bash
qemu-system-x86_64 -machine help
# find your machine type in there, if it's not present find the latest 
# and then edit xml to change the machine type
virsh edit Windows-10-Desktop-2
# change the value under <type machine="XXX"> to either the one listed under `-machine help`
```

### change pool location 
```bash
virsh shutdown my-vm-name
rsync -a /var/lib/libvirt/images/my-vm-name /var/lib/libvirt/new-dir/
virsh edit my-vm-name
(within edit window)--> :s/\/var\/lib\/libvirt\/images/\/var\/lib\/libvirt\/new-dir/g
virsh start my-vm-name
```

### delete domain completely
```bash
virsh destroy _domain-id_
virsh undefine _domain-id_

virsh vol-list --pool k8s_lab
# Name                                              Path
# ----------------------------------------------------------------------------------------------------------------------------
# coreos-1                                          /home/spil/virt/k8s_lab/coreos-1
# fedora-coreos-41.20250105.3.0-qemu.x86_64.qcow2   /home/spil/virt/k8s_lab/fedora-coreos-41.20250105.3.0-qemu.x86_64.qcow2
virsh vol-delete --pool vg0 _domain-id_.img
```

### `virsh start` permission denied error
```bash
sudo usermod -a -G kvm myusername

### /etc/libvirt/qemu.conf
user = "myusername"
group = "kvm"
```

### fix libvirt domains' traffic on NAT networks not being masqueraded because of ufw
```bash
cat /etc/default/ufw | grep DEFAULT_FORWARD_POLICY
# DEFAULT_FORWARD_POLICY="DROP" -------> ACCEPT
DEFAULT_FORWARD_POLICY="ACCEPT"

ufw reload
```

### fix libvirt dnsmasq address already in use issue
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

### get dnsmasq definitions for the vnet 
```bash
sudo ls -la /var/lib/libvirt/dnsmasq/fcos*
# -rw-r--r--. 1 root root 104 Jul 22 18:30 /var/lib/libvirt/dnsmasq/fcos_k8s_lab.addnhosts
# -rw-------. 1 root root 673 Jul 22 18:29 /var/lib/libvirt/dnsmasq/fcos_k8s_lab.conf
# -rw-r--r--. 1 root root 172 Jul 22 18:30 /var/lib/libvirt/dnsmasq/fcos_k8s_lab.hostsfile
```

### rename a domain
```bash
virsh dumpxml $DOMAIN > $SOMEFILE.xml
virsh undefine $DOMAIN
vim $DOMAIN.xml
virsh define $DOMAIN.xml
virsh destroy $DOMAIN
virsh start $DOMAIN
```

### allocate memory to a domain
```bash
virsh destroy $DOMAIN
virsh setmaxmem $DOMAIN 3G --config
virsh setmem $DOMAIN 3G --config
virsh start $DOMAIN
```

### allocate vcpu to a domain
```bash
virsh setvcpus $DOMAIN 3 --config --maximum
virsh setvcpus $DOMAIN 3 --config
```

### create an isolated network 
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

### attach multiple interfaces to 1 host
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

### basic network definition template 
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
