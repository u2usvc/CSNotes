# Access control

## Linux

### ACL

#### Basic

```bash
# get files with specific acls
getfacl -tsRp /bin /etc /home /opt /root /sbin /usr /tmp 2>/dev/null

### give user rw permissions on a file (fs should be mounted with acl option (default))
mount -o acl /dev/sda1 /mount

# basic setfacl on file
setfacl --modify u:$USER:rw $FILE
getfacl $FILE

# basic setfacl on directory
setfacl --recursive --modify u:$USER:rwX $DIRECTORY

#Remove the ACL of the file
setfacl -b file.txt 
```

### Namespaces

#### Basic

```bash
# list all namespaces
lsns

# execute command inside a namespace for a process
nsenter --target $PID --mount "$CMD"

# start a new PID namespace and enter shell in it's context
unshare --fork --pid --mount-proc /bin/bash
```

### capabilities

#### Basic

```bash
# remove binary capabilities
setcap -r $PATH

# drop process capabilities
capsh --drop=cap_net_raw --print -- -c "tcpdump"

# set capabilities
setcap [CAPABILITY][+/-][CAP_TYPE] [PATH_TO_BIN] # setcap cap_net_raw,cap_net_admin=eip /sbin/ping
```

Assign to service:

```bash
### /lib/systemd/system/*.service
[Service]
User=bob
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

Assign to user:

```bash
### /etc/security/capability.conf
cap_net_admin,cap_net_raw    jrnetadmin
```
