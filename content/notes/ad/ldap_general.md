# LDAP

## BH

### Resources

- BH collector for SCCM: <https://specterops.io/blog/2026/01/13/introducing-configmanbearpig-a-bloodhound-opengraph-collector-for-sccm/?utm_campaign=Social_Twitter_2026_01_13_ConfigManBearPig&utm_medium=Organic%20Social&utm_source=Twitter&Latest_Campaign=701Uw00000dtnUg>
- schedule task enumeration in BH: <https://github.com/1r0BIT/TaskHound>
- BH collector for user profiles stored on domain machines: <https://github.com/m4lwhere/profilehound>

- cypher cheatsheet: <https://queries.specterops.io/>

### bloodhound-python

```bash
### EXAMPLES
bloodhound-python -c All -d 'BLACKFIELD.local' -u 'support@blackfield.local' -p '#00^BlackKnight' -ns '10.10.10.192'
```

### quickstart

```bash
############
###  BH  ###
############
# tested on kali
sudo neo4j start              # will start as a daemon
http://127.0.0.1:7474/ # -> neo4j:neo4j -> change password

### EITHER
./BloodHound # -> neo4j:$CHANGED_PASSWORD
# configure dark theme in Settings=>DarkMode
# Ctrl+R to fix the blank screen!!

### OR
sudo vim /etc/bhapi/bhapi.conf
# enter the password

# navigate to 127.0.0.1:8080
# enter admin:admin
#
# firefox -> about:config -> webgl.force-enabled -> true

############
### BHCE ###
############
# run BHCE in container 
curl -L https://ghst.ly/getbhce | sudo docker compose -f - up
http://127.0.0.1:8080 => admin@password_from_command_output # wait for status change
```

### rusthound

```bash
rusthound -d certified.htb -u 'judith.mader' -p 'judith09'
```

### sharphound

```bash
### EXAMPLES
SharpHound.exe -d contoso.local --domaincontroller $DC_IP -c All
```

## OpenLDAP

### ldapadd

```bash
### add entries to LDAP db from .ldif file 
# -D: account to authenticate to
ldapadd -D "cn=Manager,dc=example,dc=org" -W -f base.ldif
```

### ldapdelete

```bash
ldapdelete $DN
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
-ZZ            # use StartTLS (works for http://)

### FILTER
nc dc someRandomAttribute  # defines attributes to return
+                          # returns ALL attributes
'(someAttribute=*)'        # filters by attribute value

### EXAMPLES
# anonymous bind (often only `-s base` will be allowed anonymously)
ldapsearch -H ldap://10.10.11.241 -x -s base
# get everything
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org'
# filter by "name" LDAP attribute
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org' 'name=DESKTOP-PD18STT'
# show only specific attributes
ldapsearch -LLL -x -H ldap://192.168.68.64 -D "Administrator@contoso.org" -w 'win2016-cli-P@$swd' -b 'dc=contoso,dc=org' name memberOf
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
