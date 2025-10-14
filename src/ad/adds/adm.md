# samba

## samba DC on debian quickstart

```bash
# remove smb.conf and let samba generate it
sudo rm /etc/samba/smb.conf

# provision the domain and become the DC
sudo samba-tool domain provision --use-rfc2307 --realm MAINNET.APERTURE.AD --domain MAINNET --server-role dc --dns-backend SAMBA_INTERNAL --adminpass 'coolpwd'

# fill resolv.conf with DC's IP and domain name
sudo vi /etc/resolv.conf
# search mainnet.aperture.ad
# nameserver 192.168.1.100

# copy generated krb5.conf to /etc/ (`domain provision` outputs the generated file path)
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# change dns forwarder if needed
sudo vi /etc/samba/smb.conf
# dns forwarder = 1.1.1.1

# set a static address
sudo vi /etc/network/interfaces
# allow-hotplug ens18
# iface ens18 inet static
#         address 192.168.1.100/24
#         gateway 192.168.1.1

# start samba
sudo samba
# reboot
sudo reboot

# test
sudo apt install smbclient
sudo smbclient -L localhost -N
```

# FreeIPA
