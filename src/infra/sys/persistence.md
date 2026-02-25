# Persistence

## Linux

### RDP

#### XRDP setup

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
# now logout from desktop and use remmina to remotely connect
```
