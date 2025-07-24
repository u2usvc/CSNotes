# SELinux
## general
```bash
# policies are stored under /etc/selinux/$PROFILE/contexts/files/file_contexts, you can just cat this file
semanage fcontext -l | grep http_log_t

# policy modules are stored in dirs such as /var/lib/selinux/targeted/active/modules/400/$MODULE_NAME
# list modules (you'll find default modules, as well as custom (installed with `semodule -i`) here)
semodule -l | grep $MODULE_NAME
```

## Custom pols
if you want to edit the policy, just edit, recompile and install it again.
```bash
### generate base policy
mkdir mydaemon_pol && cd mydaemon_pol
# --init is for init daemons, you can substitute --application or any other skeleton there
# it doesn't really matter much because later you'd still need to delete some unnecessary permissions from there
sepolicy generate --init /usr/local/bin/mydaemon
restorecon -v /usr/local/bin/mydaemon

### optionally extend the policy (don't forget to add types to scope)
echo "type var_log_t;" >> mydaemon.te
echo "allow mydaemon_t var_log_t:file { open write getattr };" >> mydaemon.te

### compile and install the policy (mydaemon.PP)
make -f /usr/share/selinux/strict/include/Makefile mydaemon.pp
semodule -i mydaemon.pp

### if you get errors upon module installation use dd to understand an error
sudo semodule -i mymodule.pp
# Bad type declaration at /var/lib/selinux/targeted/tmp/modules/400/mymodule/cil:6
# Failed to build AST
cat mymodule.pp | /usr/libexec/selinux/hll/pp > mymodule.cil
head -6 mymodule.cil
# (type abrt_t)

### if you encounter problems after policy installation check logs
cat /var/log/audit/audit.log | grep SELINUX_ERR
```

```bash
### defining custom application-only file context
# this will create polybar_xdg_config_t type
type polybar_xdg_config_t;
# this will allow base domain (in this case polybar_t) every permission on polybar_xdg_config_t
files_type(polybar_xdg_config_t);
```

## type transition
```bash
type_transition initrc_t sshd_exec_t : process sshd_t;
# When an initrc_t process executes a file with context sshd_exec_t, 
# then the resulting process should run in the sshd_t context.

### REQUIREMENTS:
### let's say initrc_t should execute sshd_exec_t and it should transition to sshd_t
# ~ The origin domain (initrc_t) has execute permission on the file (that is labeled sshd_exec_t)
sesearch -s initrc_t -t sshd_exec_t -c file -p execute -A
allow initrc_t sshd_exec_t : file { execute open read };
# ~ The file context itself (sshd_exec_t) is identified as an entry point for the target domain (sshd_t)
sesearch -s sshd_t -t sshd_exec_t -c file -p entrypoint -A
allow sshd_t sshd_exec_t : file entrypoint;
# ~ The origin domain (initrc_t) is allowed to transition to the target domain (sshd_t)
sesearch -s initrc_t -t sshd_t -c process -p transition -A
allow initrc_t sshd_t : process transition;
# ~ The final type (sshd_t) should be within the scope of a role it's 
# being to (e.g. if initrc_t -> system_r), then
seinfo -r system_r -x | grep sshd_t
role system_r type sshd_t # inside the .te
# ~ The binary itself should be of exec type (sshd_exec_t)
ls -laZ /usr/sbin/sshd
semanage fcontext --add --seuser system_u --type sshd_exec_t "/usr/sbin/sshd"
restorecon /usr/sbin/sshd
```

## policy module compilation
```bash
### COMPILE CHEAT SHEET
# prerequisites: you have an audit2allow file named $FILE.te (type enforcement) (Note the file extension) (to do that see * audit2allow)
# make sure that the module name inside the file maches the filename

# compile the policy into .mod file
checkmodule -M -m $FILE.te -o $FILE.mod
# package the module file (.mod) into a policy package (.pp)
semodule_package -o $FILE.pp -m $FILE.mod
# install the policy package as a policy module
semodule -i $FILE.pp


# remove policy module by name
semodule -r $MODULE_NAME
```

## audit2allow
```bash
### generate allow rules from dmesg output (this will generate .te and .pp files)
# if startup denied logs
dmesg | grep  denied | audit2allow -r -M $MODULE_NAME # MODULE_NAME can be anything
# if system runtime denied logs
grep denied /var/log/audit/audit.log | audit2allow -r -M $MODULE_NAME
# install policy
semodule -i $MODULE_NAME.pp

# you can delete these files afterwards
```

## Add sudo support
```bash
id -Z
# staff_u:staff_r:staff_t

newrole -r sysadm_r
# Password: (Enter your password)

id -Z
# staff_u:sysadm_r:sysadm_t
@end
Or using sudo:
@code bash
### /etc/sudoers
%wheel ALL=(ALL) TYPE=sysadm_t ROLE=sysadm_r ALL
# OR to a single user
fuser ALL=(ALL) TYPE=sysadm_t ROLE=sysadm_r ALL
```

## confine existing users
```bash
semanage login -a -s staff_u john
restorecon -RvF /home/john
```


## Tips
If `/home` is mounted on top of the underlying `/home` directory, in order for the top `/home` to be mounted with the correct labeling the bottom `/home` should have the correct label first:
```bash
# assuming ls -dZ /home returns system_u:object_r:home_root_t:s0
mkdir /mnt/test

mount --bind / /mnt/test
chcon system_u:object_t:home_root_t:s0 /mnt/test/home

umount /mnt/test
rmdir /mnt/test
```
