# git server

```bash
groupadd git 
# useradd -m -g git -d /var/git -s /usr/bin/git-shell git
useradd -m -g git -d /var/git -s /bin/bash git
sudo mkdir /var/git/.ssh && sudo chmod 700 /var/git/.ssh
sudo touch /var/git/.ssh/authorized_keys && sudo chmod 600 /var/git/.ssh/authorized_keys
# write a public key there

sudo su
cd /var/git
mkdir project.git
cd project.git
git init --bare
sudo chown --recursive git:git /var/git

##############
### OPENRC ###
##############
### /etc/conf.d/git-daemon
GIT_USER="git"
GIT_GROUP="git"
GITDAEMON_OPTS="--syslog --export-all --enable=receive-pack --base-path=/var/git"


sudo mkdir /var/git
sudo chown git:git /var/git
rc-service sshd start
rc-service git-daemon start
###

###############
### SYSTEMD ###
###############
### /etc/systemd/system/git-daemon.service
[Unit]
Description=Git Daemon
After=network.target

[Service]
ExecStart=/usr/libexec/git-core/git-daemon --base-path=/var/git --export-all --enable=receive-pack --syslog --detach
User=git
Group=git
Restart=always

[Install]
WantedBy=multi-user.target


sudo mkdir /var/git
sudo chown git:git /var/git
sudo systemctl start git-daemon sshd
###

### SELinux
sudo semanage fcontext -a -t ssh_home_t "/var/git/\.ssh(/.*)?"
sudo restorecon -FRvv /var/git/.ssh
sudo systemctl restart sshd

# ensure the private key for the host is in ~/.ssh/config
# for any port
git remote add origin ssh://git@host.com/var/git/project.git
```
