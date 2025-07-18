# git server
## manual setup
```bash
groupadd git 
# useradd -m -g git -d /var/git -s /usr/bin/git-shell git
useradd -m -g git -d /var/git -s /bin/bash git
sudo mkdir /var/git/.ssh && sudo chmod 700 /var/git/.ssh
sudo touch /var/git/.ssh/authorized_keys && sudo chmod 600 /var/git/.ssh/authorized_keys
# write a public key there

cd /var/git
mkdir project.git
cd project.git
git init --bare
# Initialized empty Git repository in /srv/git/project.git/
sudo chown --recursive git:git /var/git

### /etc/conf.d/git-daemon
GIT_USER="git"
GIT_GROUP="git"
GITDAEMON_OPTS="--syslog --export-all --enable=receive-pack --base-path=/var/git"


sudo mkdir /var/git
sudo chown git:git /var/git
# ENSURE GITD DAEMON IS RUNNING FIRST
rc-service git-daemon start

# for any port!
git remote add origin ssh://git@192.168.1.69/var/git/nvim_vault.git
```

