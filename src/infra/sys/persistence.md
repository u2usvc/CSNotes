# Persistence

## C2

### AdaptixC2

#### setup

```bash
cd ~
mkdir utils
cd utils
git clone https://github.com/Adaptix-Framework/AdaptixC2.git
chmod +x pre_install_linux_all.sh
sudo ./pre_install_linux_all.sh server
make server-ext
cd dist
openssl req -x509 -nodes -newkey rsa:2048 -keyout server.rsa.key -out server.rsa.crt -days 3650

sudo bash -c 'cat <<EOF > /etc/systemd/system/adaptixserver.service
[Unit]
Description=AdaptixC2

[Service]
ExecStart=/home/user/utils/AdaptixC2/dist/adaptixserver -profile /home/user/utils/AdaptixC2/dist/profile.yaml
Restart=always
User=root
WorkingDirectory=/home/user/utils/AdaptixC2/dist

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable adaptixserver.service
sudo systemctl start adaptixserver.service
sudo systemctl status adaptixserver.service
```

##### BOF

```bash
cd ~/utils/
sudo apt install g++-mingw-w64-x86-64-posix  gcc-mingw-w64-x86-64-posix  mingw-w64-tools
git clone https://github.com/Adaptix-Framework/Extension-Kit
cd Extension-Kit
make
```

Load all modules in AdaptixC2 client: `Main menu -> Script manager -> Load new` and select the `extension-kit.axs` file.

After doing that, you will be able to use that BOF more conveniently through an agent console directly (e.g. `ldap get-users -ou "OU=Users,DC=domain,DC=local" -dc dc01.domain.local -a description,mail`)
However this approach requires an axscript (e.g. `AD-BOF/ad.axs`) to be written for each BOF. If you just wanna execute any BOF you can just use the `execute bof` command (e.g. `execute bof /home/user/utils/bofs/bin/ldapsearch.o`), (ofc adaptix won't be able to understand this BOF, however you may observe it's traffic under adaptixserver output logs).

After executing any of the above mentioned commands, the BOF will be automatically uploaded to the agent, injected and executed in-memory.

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
