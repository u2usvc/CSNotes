# MikroTik RouterOS

## MAC TELNET

```bash
/ip/service/enable numbers=telnet
/interfaces/print

sudo apt install mactelnet-client
mactelnet $MAC
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
