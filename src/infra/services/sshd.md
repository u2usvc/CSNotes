# sshd
## Reasonably secure setup
1. Change sshd security settings
```bash
######## /etc/ssh/sshd_config
### do NOT install sudo

### DISABLE ROOT LOGIN
AllowUsers $USERNAME $USERNAME
PermitRootLogin no

### DISABLE PASSWORD AUTHENTICATION
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PubkeyAuthentication yes

### REQUIRE BOTH PASSWORD AND PRIVATE KEY
AuthenticationMethods "publickey,password"
PasswordAuthentication yes

### change default port
Port 5555
```

2. Enable FW
```bash
ufw enable
```

3. Create an unprivileged user
```bash
adduser myuser
```


4. Setup autoupdate
```bash
### DEBIAN
sudo apt update && sudo apt upgrade
sudo apt install unattended-upgrades

# /etc/apt/apt.conf.d/50unattended-upgrades
# ensure the following are present. (they are present by default)
"origin=Debian,codename=${distro_codename},label=Debian";
"origin=Debian,codename=${distro_codename},label=Debian-Security";
"origin=Debian,codename=${distro_codename}-security,label=Debian-Security";

sudo systemctl start unattended-upgrades
sudo systemctl enable unattended-upgrades

# observe
cat /var/log/unattended-upgrades/unattended-upgrades.log

```

5. Setup port knocking
```bash
# install knockd
apt install knockd

### /etc/knockd.conf
[options]
UseSyslog
Interface = enp3s0

[SSH]
sequence    = 7000,8000,9000
seq_timeout = 5
tcpflags    = syn
start_command = ufw allow from %IP% to any port 5555
stop_command = ufw delete allow from %IP% to any port 5555
cmd_timeout   = 60


### /etc/default/knockd
START_KNOCKD=1
KNOCKD_OPTS="-i enp3s0"

# usage with port knocking
for ports in 7000 8000 9000; do nmap -Pn --max-retries 0 -p $ports 46.1 $MY_SRV; done
ssh -i $SSH_KEY_PATH -p 5555 myuser@$MY_SRV
```
