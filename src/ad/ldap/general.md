# General

## BH

### collectors

```bash
bloodhound-python -c All -d 'BLACKFIELD.local' -u 'support@blackfield.local' -p '#00^BlackKnight' -ns '10.10.10.192'

rusthound -d certified.htb -u 'judith.mader' -p 'judith09'

SharpHound.exe -d contoso.local --domaincontroller $DC_IP -c All
```

### quickstart

```bash
############
###  BH  ###
############
sudo neo4j start
http://127.0.0.1:7474/ # -> neo4j:neo4j -> change password
./BloodHound # -> neo4j:$CHANGED_PASSWORD
# configure dark theme in Settings=>DarkMode

############
### BHCE ###
############
# run BHCE in container 
curl -L https://ghst.ly/getbhce | sudo docker compose -f - up
http://127.0.0.1:8080 => admin@password_from_command_output # wait for status change
```

## pywerview

```bash
# search 'administrator' user
pywerview get-netuser -w contoso.org --dc-ip 192.168.68.64 -u TestAcc -p 'win2016-cli-P@$swd' --username administrator

# get users
pywerview get-netuser -w sequel.htb --dc-ip 10.10.11.51 -u rose -p 'KxEPkKe6R8su'

# get 'management' group
pywerview get-netgroup -w certified.htb --dc-ip 10.10.11.41 -u judith.mader -p judith09 --full-data --groupname 'Management'

# check acls against management group
pywerview get-objectacl -u judith.mader -p 'judith09' -t 10.10.11.41 --resolve-sids --sam-account-name Management

# get group members
pywerview get-netgroupmember -w certified.htb --dc-ip 10.10.11.41 -u judith.mader -p judith09 --groupname 'Management'

# get DC
pywerview get-netdomaincontroller -w certified.htb --dc-ip 10.10.11.41 -u judith.mader -p judith09
```

## OpenLDAP

### ldapadd

```bash
### add entries to LDAP db from .ldif file 
# -D: account to authenticate to
ldapadd -D "cn=Manager,dc=example,dc=org" -W -f base.ldif
```

### ldapsearch

```bash
### PARAMETERS
-H ldapuri     # ldap-server uri (required for non-localhost searches)
-W             # Prompt for simple authentication
-x             # use simple authentication instead of SASL
-D binddn      # bind to ldap directory via the DN
-f             # ldif file to add
-b searchbase  # object to search for (i.e. database to search under) (e.g. cn=config)
-s {base|one|sub|children} # searchbase (most probably you want "sub" for subtree (recursive children) search)
-LLL           # print in LDIF format
-Y {EXTERNAL,DIGEST-MD5,GSSAPI} # Set the SASL auth mechanism

### FILTER
nc dc someRandomAttribute  # defines attributes to return
+                          # returns ALL attributes
'(someAttribute=*)'        # filters by attribute value

### EXAMPLES
# TLS bind
env TLS_CACERT=. TLS_CERT=. TLS_KEY=. ldapsearch -H "ldaps://dc-1.aisp.aperture.local" \
-Y EXTERNAL -b 'dc=aisp,dc=aperture,dc=local' -s sub '*' +

# anonymous bind (often only `-s base` will be allowed anonymously)
ldapsearch -H ldap://10.10.11.241 -x -s base
# get everything
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org'
# filter by "name" LDAP attribute
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org' 'name=DESKTOP-PD18STT'
# show only specific attributes
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org' name memberOf
```

### ldapmodify

```bash
### USAGE: same as ldapadd

### EXAMPLE (- ARE ACTUALLY IMPORTANT)
dn: cn=Modify Me,dc=example,dc=com
changetype: modify
replace: mail
mail: modme@example.com
-
add: title
title: Grand Poobah
-
add: jpegPhoto
jpegPhoto:< file:///tmp/modme.jpeg
-
delete: description
-
```

### ldapdelete

```bash
ldapdelete $DN
```
