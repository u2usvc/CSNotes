---
title: "NFS with LDAP and Kerberos Authentication"
date: 2023-09-01
description: "A guide for the deployment of OpenLDAP w/ KRB5 KDC to provide authentication for NFS"
---

## About

This article will consist of a deployment of an OpenLDAP database in a combination with Kerberos KDC daemon with the end goal of providing unified authentication to a local NFS across the domain.
Local network will consist of gentoo-based machines, however the deployment is similar across all GNU/Linux distributions.

The point of this article is more to just describe my own experience implementing this, perhaps it may provide a unified source on that topic to someone interested, as well as extending it a little bit, as, honestly, I found information on it on the internet kinda vague and all over the place.
This article is prone to errors, do NOT treat things described here as 100% correct, manual configuration of things like these tend to be fragile and might not work for everything and everyone. Also, this article is quite large and it is noticibly difficult to write it all in one-go, coordinated and keeping a unified pace.
If you found a mistake, please contact me.


## OpenLDAP FAQ

Some misconceptions that can arise:
1) The database with DN: cn=config is a configuration database and is a separate database from any other DBs.
2) objects under cn=config, e.g. olcDatabase=* are the configuration objects for other databases and are children objects of cn=config root entry. They are not properties of the databases they represent.
3) mdb is just one type of the backend db. The backend db is the main database that should be used to hold the data. Backend databases, same as any other, are not limited and you can create any number of those.
4) rootdn's of the databases are independent and exclusive to the databases they are the rootdns of. Each database should have it's own rootdn and rootdn of one database is unable to reach the another database.



## Things to try in the future (i.e. things not described in this article)

1. OpenLDAP replication and KDC replicas
2. Full SELinux integration and automatic SELinux policy sync (SELinux remote policy server)
3. MFA with OTP
4. auto mount with AutoFS
5. PAM integration


## Configuring server

### Package installation

Start with package installation. As server machine's gentoo-based, gentoo's native package management solution "portage" will be utilized.
I prefer to take note of the packages I install, so a custom package set will be created for portage.
```bash
cat > /etc/portage/sets/olkrb << EOF
net-nds/openldap
net-fs/nfs-utils
app-crypt/mit-krb5
net-nds/gssproxy
EOF
```

Next, define USE flags that will be necessary for a functioning environment in /etc/portage/package.use.
```bash
$ tail -n 4 /etc/portage/package.use
### olkrb
net-nds/openldap kerberos sasl debug
app-crypt/mit-krb5 openldap pkinit keyutils
net-fs/nfs-utils kerberos
```

Finally, merge the packages:
```bash
emerge --ask @olkrb
```

I'd suggest to list and unpack RFC's for future reference and greping through it:
```bash
equery f openldap | grep -e 'doc.*rfc' -A 1 | head -1
```

Versions for reference:
```bash
[ebuild   R   ~] net-nds/openldap-2.6.6-r2:0/2.6::gentoo  USE="cleartext crypt debug kerberos sasl (selinux) ssl syslog -argon2 -autoca -cxx -experimental -gnutls -iodbc -kinit -minimal -odbc -overlays -pbkdf2 -perl -samba -sha2 -smbkrb5passwd -static-libs -systemd -tcpd -test" ABI_X86="32 (64) (-x32)" 0 KiB
[ebuild   R    ] app-crypt/mit-krb5-1.21.3::gentoo  USE="keyutils openldap pkinit (selinux) -doc -lmdb -nls -test -xinetd" ABI_X86="32 (64) (-x32)" CPU_FLAGS_X86="aes" 0 KiB
[ebuild   R    ] net-fs/nfs-utils-2.6.4-r11::gentoo  USE="(caps) kerberos libmount nfsv3 nfsv4 (selinux) uuid -junction -ldap -sasl -tcpd" 0 KiB
```


### Configuring OpenLDAP

#### Initial configuration

##### The file creation

Start with LDAP database configuration, as slapd.conf static configuration solutions are deprecated and OpenLDAP uses dinamic configuration, here it will be used as well. Dinamic LDIF-based configuration directory is based in /etc/openldap/slapd.d. First, initial context has to be generated. I'd prefer to start with a fresh config directory and build on top of it.
At this point, slapd.d is empty, but I have the default /etc/openldap/slapd.ldif and I'll use it to generate slapd.d content (You can use slapd.conf in the same manner, but I would stick to more up-to-date alternative).
The only thing I'll do for now is change the domain to a suitable one, as well is the rootdn and it's password. For this demonstration, assume that:
1. The domain of question will be ops.olkrb.local
2. The server's FQDN on which OpenLDAP and Kerberos KDC are based will be dc-1.ops.olkrb.local
3. The test client will be rw-msi-1.ops.olkrb.local
4. DC-1 also runs a dnsmasq server which provides DNS services to local network.
   !!!
```bash
# /etc/dnsmasq.conf
domain=ops.olkrb.local
local=/ops.olkrb.local/
```
   P.S. it's generally not recommended to use .local TLD, because of it's reservation for mDNS, however in my case, the network does not contain any mDNS resolvers.

5) Yes, the entire infrastructure will be running under SELinux MAC (tho, permissive, for now), tho I will additionally mention UNIX-like DAC policies, as well as ACLs, in case the reader does not have SELinux-enabled system.

The mdb and config rootdn's password hashes can be generated easily using slappasswd utility for initial access.
You'll need to generate it. I use pass to keep track of passwords I create, so first, i'm gonna generate and store the passwords in my pass directory.
```bash
pass generate selfhosted/olkrb/openldap/mdb1/root
# The generated password for selfhosted/olkrb/openldap/mdb1/root is:
# ~eyUjIdN`),~KN/y:_`'+b"?E

pass generate selfhosted/olkrb/openldap/config/config
# The generated password for selfhosted/olkrb/openldap/mdb1/root is:
# F4VQ$)}+7W!yE{3@)4]r99>A-
```

Next, generate the hashes using slappasswd utility:
```bash
slappasswd
# New password:
# Re-enter new password:
# {SSHA}uejzDvYG13J+j7uwZygFKtZSIBwKCsy2

slappasswd
# New password:
# Re-enter new password:
# {SSHA}Huzjh0ItsPYzZFqm7EbEpE5eJNiiN0Qt
```

Finally, the slapd.ldif file should look like this
```bash
dn: cn=config
objectClass: olcGlobal
cn: config
olcArgsFile: /var/run/slapd.args
olcPidFile: /var/run/slapd.pid

dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath:	/usr/lib64/openldap/openldap
olcModuleload:	back_mdb.la

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file:///etc/openldap/schema/core.ldif

dn: olcDatabase=config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: config
olcRootPW: {SSHA}Huzjh0ItsPYzZFqm7EbEpE5eJNiiN0Qt
olcAccess: to * by * none

dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbMaxSize: 1073741824
olcSuffix: dc=ops,dc=olkrb,dc=local
olcRootDN: cn=root,dc=ops,dc=olkrb,dc=local
olcRootPW: {SSHA}uejzDvYG13J+j7uwZygFKtZSIBwKCsy2
olcDbDirectory:	/var/lib/openldap-data
olcDbIndex: objectClass eq

dn: olcDatabase=monitor,cn=config
objectClass: olcDatabaseConfig
olcDatabase: monitor
olcRootDN: cn=config
olcMonitoring: FALSE
```

1) You can actually specify the slapd-formatted value of a certificate DN inside the olcRootDN attribute and skip binding DNs with olcAuthzRegexp later, but I'll avoid duing that to keep a sensical formatting of this value.

As you may notice, MDB (Memory-Mapped Database) is used as a backend and that database will be stored at /var/lib/openldap-data directory.
I will create it before the daemon start.
```bash
mkdir /var/lib/openldap-data 
chmod 700 /var/lib/openldap-data
```

Finally, convert slapd.ldif and set ldap service-user as a directory owner.
```
slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif
chown -R ldap:ldap /etc/openldap/slapd.d
```
Or, if you modified slapd.conf you can use
```
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
```


##### Debugging

slapd init script is, in fact, executing the "/usr/lib64/openldap/slapd" binary, which has some useful debugging options, that, in OpenRC's case (not sure about systemd), are not being forwarded through slapd init script. So if your script failes to execute, you can try the following:
1) Mimic the context of execution observing the slapd shell script and modify it a little bit to get the context. You can use a custom function for this:
```bash
_DEBUG="on"
function DEBUG()
{
  [ "$_DEBUG" == "on" ] &&  $@
}

start() {

  ...

  COMMAND="start-stop-daemon --start --pidfile ${PIDFILE} --exec /usr/lib64/openldap/slapd -- -u ldap -g ldap ${OPTS}"
  DEBUG echo "DEBUG COMMAND=${COMMAND}"
  eval ${COMMAND}
  eend $?
}
```

Upon execution you should get something like this:
```
* Starting ldap-server ...
DEBUG COMMAND=start-stop-daemon --start --pidfile /run/openldap/slapd.pid --exec /usr/lib64/openldap/slapd -- -u ldap -g ldap -f /etc/openldap/slapd.conf -h 'ldaps:// ldap:// ldapi://%2frun%2fopenldap%2fslapd.sock'
```
Now you can mimic an execution context adding some debug options. You can also log into /var/log/messages with an -s option:
```
start-stop-daemon --start --pidfile /run/openldap/slapd.pid --exec /usr/lib64/openldap/slapd -- -d 255 -u ldap -g ldap -f /etc/openldap/slapd.conf -h 'ldaps:// ldap:// ldapi://%2frun%2fopenldap%2fslapd.sock'
```
You should get a little bit more helpful error report now. In my case, for some reason slapd was not closing it's listeners after the stop/restart.


##### Nuances

1) You may've noticed that I haven't defined frontend database explicitly. That is because on manual olcDatabase=schema specification, slapadd will create the olcDatabase=frontend configuration file for us, so contrary to the [OpenLDAP documentation](https://www.openldap.org/doc/admin26/slapdconf2.html#Configuration%20Example), specifying them in combination with each other will result in an error:
```
slapadd: could not add entry dn="olcDatabase={-1}frontend,cn=config" (line=615): Already exists
```

2) Before you run the daemon with /etc/init.d/slapd you need to make sure that slapd.conf file is not being specified with an -f option of the slapd executable and that -F option value is being defined correctly, otherwise the daemon's not gonna function property and you will have problems with it's handling by the init system.

3) If running under SELinux, unless your user has correct context assigned to it (e.g. child processes are being executed under the domain staff_u:staff_r:staff_t), the slapd daemon may fail to write to /var/log/openldap-data, which is by default of context system_u:object_r:var_lib_t. 

4) If it is not your first interaction with OpenLDAP and slapd fails to start there is a possibility that your configuration files were mistreated. Try to rewrite your files. For example, if your system is running portage you can do it using the combination of "emerge --noconfmem" and "dispatch-conf".

5) In my case, I had to modify the default start-stop-daemon command to include -F as an option for /usr/lib64/openldap/slapd, because the default behaviour of the init script was to include the -f option pointing to the deprecated "slapd.conf", I specified /var/lib/openldap-conf since I am using this custom path as a configuration directory:
```
eval start-stop-daemon --start --pidfile ${PIDFILE} --exec /usr/lib64/openldap/slapd -F /var/lib/openldap-conf -- -u ldap -g ldap -h 'ldaps:// ldap://'"
```
LDAPI:// transport is removed from slapd init, since this article assumes that clients will operate from the machine separate from DC-1 and IPC is not necessary here. LDAP:// transport will later be removed also, once TLS config is completed.

6) Note the pidfile bit within the main execution context, make sure the init script defines paths matching slapd configuration, for example:
```bash
# /etc/init.d/slapd
PIDDIR=/run/openldap
PIDFILE=$PIDDIR/$SVCNAME.pid

# /etc/slapd.d/cn=config.ldif
olcArgsFile: /run/openldap/slapd.args
olcPidFile: /run/openldap/slapd.pid
```

7) Obviously, make sure ldap user has all needed ownerships and permission bits, i.e. on files in: configuration directories, /run/openldap, data directory.

8) Make sure the ports slapd listens on are free.


##### Checking if everything works

At this point, a deployment of a fully functional database should be possible by running the slapd daemon (DSA).
I will add it to my default init directory and run it using OpenRC utility stack, if your system utilizes systemd as an init system - use systemctl binary for that.
Double-check if everything starts/stops and works properly.
```bash
rc-service slapd start
# * Starting ldap-server ...

rc-service slapd status
# * status: started

netstat -tulpan | grep slapd
# tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      4707/slapd
# tcp        0      0 0.0.0.0:636             0.0.0.0:*               LISTEN      4707/slapd
# tcp6       0      0 :::389                  :::*                    LISTEN      4707/slapd
# tcp6       0      0 :::636                  :::*                    LISTEN      4707/slapd

rc-service slapd stop

rc-service slapd status
# * status: stopped

netstat -tulpan | grep slapd

rc-service slapd start
# * Starting ldap-server ...
```

Check that the databases are accessible and the configuration is valid.
Note the searchbase specification "-s" and filters after it. the '(objectClass=*)' filter is default and included for demonstration, the '+' requests operational attributes (e.g. entryUUID, createTimestamp), the '\*' (note an apostrophe) is requesting all regular attributes. The searchbase parameter is set to base-object because the backend MDB is empty. The root DSE object (OpenLDAProotDSE in OpenLDAP) being returned with empty searchbase (-b) is a special entity within LDAP and does not belong to any database.
Make sure to search against 
```bash
ldapsearch -x -W -H 'ldap://127.0.0.1:389' -b 'cn=config' -D 'cn=config' -s sub '(objectClass=*)' '+' '*'

ldapsearch -x -W -H 'ldap://127.0.0.1:389' -b '' -D 'cn=root,dc=ops,dc=olkrb,dc=local' -s base '(objectClass=*)' '+' '*'
# OR JUST
ldapsearch -W -D 'cn=root,dc=ops,dc=olkrb,dc=local' -s base namingContexts
```


#### Setting up TLS (PKI)

For secure communication with DSA set up TLS, I'd assume certificates are not generated yet.
First, all required files have to be created, which include database and serial number files for certificates and CRLs.
```bash
pass generate selfhosted/olkrb/cert/olkrb-eca.key
cd /etc/certs
mkdir -p {eca,sca}/{db,private}
cp /dev/null eca/db/olkrb-eca.db
cp /dev/null eca/db/olkrb-eca.db.attr
cp /dev/null sca/db/olkrb-sca.db
cp /dev/null sca/db/olkrb-sca.db.attr

touch eca/db/{olkrb-eca.crl.srl,olkrb-eca.crt.srl}
echo -n "01" > eca/db/olkrb-eca.crl.srl && echo -n "01" > eca/db/olkrb-eca.crt.srl
touch sca/db/{olkrb-sca.crl.srl,olkrb-sca.crt.srl}
echo -n "01" > sca/db/olkrb-sca.crl.srl && echo -n "01" > sca/db/olkrb-sca.crt.srl
```


##### Defining a configuration for and creating an enterprise CA

Define the configuration according to the following requirements:
1. define standard req, ca_dn, default_ca, any_pol
2. match policies specified accordingly: CN must be present as it is used for binding on a DSA side, DC must match 'olkrb.local' and organization name must match 'OlKrb'
3. Set CA:true, certificate and CRL signing capabilities for subsequent subordinate CA certificate generation
4. mds is set to to sha256 to ensure later slapd compatability

```bash
# cat /etc/certs/eca/olkrb-eca.conf
[ default ]
ca = olkrb-eca
dir = .
[ req ]
default_bits = 2048
encrypt_key = yes
default_md = sha256
utf8 = yes
string_mask = utf8only
prompt = no # Don't prompt for DN
distinguished_name = ca_dn
req_extensions = ca_reqext
[ ca_dn ]
0.domainComponent = "local"
1.domainComponent = "olkrb"
organizationName = "OlKrb"
organizationalUnitName = "ECA"
commonName = "ECA"
[ ca_reqext ]
keyUsage = critical,keyCertSign,cRLSign
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
CipherString = ECDHE-ECDSA-AES128-GCM-SHA256
[ ca ]
default_ca = enterprise_ca
[ enterprise_ca ]
certificate = $dir/$ca.crt # The CA cert                
private_key = $dir/private/$ca.key # CA private key     
new_certs_dir = $dir/ # Certificate archive             
serial = $dir/db/$ca.crt.srl # Serial number file       
crlnumber = $dir/db/$ca.crl.srl # CRL number file       
database = $dir/db/$ca.db # Index file                  
unique_subject = no # Require unique subject
default_days = 10950 # How long to certify for (30 years)
default_md = sha256
policy = match_pol # Default naming policy
email_in_dn = no # Add email to cert DN
preserve = no # Keep passed DN ordering
name_opt = ca_default # Subject DN display options
cert_opt = ca_default # Certificate display options
copy_extensions = none # Copy extensions from CSR
x509_extensions = signing_ca_ext # Default cert extensions
default_crl_days = 365 # How long before next CRL
crl_extensions = crl_ext # CRL extensions
[ match_pol ]
domainComponent = match # Must match 'olkrb.org'
organizationName = match # Must match 'OlKrb'
organizationalUnitName = optional # Included if present
commonName = supplied # Must be present
[ any_pol ]
domainComponent = optional
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional
[ enterprise_ca_ext ]
keyUsage = critical,keyCertSign,cRLSign
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
[ subordinate_ca_ext ]
keyUsage = critical,keyCertSign,cRLSign
basicConstraints = critical,CA:true,pathlen:0
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
[ crl_ext ]
authorityKeyIdentifier = keyid:always
```
Create an "ECA" and self-sign it's certificate
```bash 
# creating csr and private key for the ECA (utilizing enterprise-ca.conf), inserting PEM passphrase generated earlier
cd /etc/certs/eca
openssl req -new \
-config olkrb-eca.conf \
-out olkrb-eca.csr \
-keyout private/olkrb-eca.key

# self-sign ECA 
openssl ca -config olkrb-eca.conf –selfsign \
-in olkrb-eca.csr \
-out olkrb-eca.crt \
-extensions enterprise_ca_ext
```


##### Defining a configuration for and creating a subordinate CA

Now, create a subordinate that is going to be the signing CA for client and server certificates.
The configuration file for the subordinate CA is very similar with the main difference being, extensions defined in it, as this CA would have to be used to generate both client and server certificates, which are not CA certificates.
Additionally, extensions for kerberos KDC and clients are added according to the [PKINIT configuration implementation docs](https://web.mit.edu/kerberos/krb5-latest/doc/admin/pkinit.html) with some minor adjustments, since the CA is already generated.
Note the SAN definition in krb_client_cert and kdc_ext, this is PKINIT-formatted and without it additional options a will have to be specified on KDC-side.
```bash
[ default ]
ca = olkrb-sca
dir = .
[ req ]
default_bits = 2048
encrypt_key = yes
default_md = sha256
utf8 = yes
string_mask = utf8only
prompt = no
distinguished_name = ca_dn
req_extensions = ca_reqext
[ ca_dn ]
0.domainComponent = "local"
1.domainComponent = "olkrb"
organizationName = "OlKrb"
organizationalUnitName = "SCA"
commonName = "SCA"
[ ca_reqext ]
keyUsage = critical,keyCertSign,cRLSign
basicConstraints = critical,CA:true,pathlen:0           # PATHLEN:0 DIFF
subjectKeyIdentifier = hash
[ ca ]
default_ca = signing_ca # The default CA section
[ signing_ca ]
certificate = $dir/$ca.crt # The CA cert                
private_key = $dir/private/$ca.key # CA private key     
new_certs_dir = $dir/ # Certificate archive             
serial = $dir/db/$ca.crt.srl # Serial number file       
crlnumber = $dir/db/$ca.crl.srl # CRL number file       
database = $dir/db/$ca.db # Index file                  
unique_subject = no # Require unique subject
default_days = 1825 # How long to certify for
default_md = sha256 # MD to use
policy = match_pol # Default naming policy
email_in_dn = no # Add email to cert DN
preserve = no # Keep passed DN ordering
name_opt = ca_default # Subject DN display options
cert_opt = ca_default # Certificate display options
copy_extensions = copy # Copy extensions from CSR
# x509_extensions = email_ext # Default cert extensions
default_crl_days = 7 # How long before next CRL
crl_extensions = crl_ext # CRL extensions
[ match_pol ]
domainComponent = match # Must match 'olkrb.local'
organizationName = match # Must match 'OlKrb'
organizationalUnitName = optional # Included if present
commonName = supplied # Must be present
[ any_pol ]
domainComponent = optional
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional
[ server_ext ]
# slapd, kdc
keyUsage = critical,digitalSignature,keyEncipherment # -keyCertSign,cRLSign +digitalSignature,keyEncipherment
basicConstraints = CA:false # -critical -CA:true
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
[ client_ext ]
# kadmind, rootdns, RWs
keyUsage = critical,digitalSignature,nonRepudiation,keyEncipherment
basicConstraints = CA:false
extendedKeyUsage = clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
[ crl_ext ]
authorityKeyIdentifier = keyid:always

[krb_client_cert]
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment,keyAgreement
extendedKeyUsage=1.3.6.1.5.2.3.4
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
issuerAltName=issuer:copy
subjectAltName=otherName:1.3.6.1.5.2.2;SEQUENCE:princ_name
[princ_name]
realm=EXP:0,GeneralString:${ENV::REALM}
principal_name=EXP:1,SEQUENCE:principal_seq
[principal_seq]
name_type=EXP:0,INTEGER:1
name_string=EXP:1,SEQUENCE:principals
[principals]
princ1=GeneralString:${ENV::CLIENT}

[ kdc_ext ]
basicConstraints=CA:FALSE
keyUsage=nonRepudiation,digitalSignature,keyEncipherment,keyAgreement
extendedKeyUsage=1.3.6.1.5.2.3.5
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
issuerAltName=issuer:copy
subjectAltName=otherName:1.3.6.1.5.2.2;SEQUENCE:kdc_princ_name
[kdc_princ_name]
realm=EXP:0,GeneralString:${ENV::REALM}
principal_name=EXP:1,SEQUENCE:kdc_principal_seq
[kdc_principal_seq]
name_type=EXP:0,INTEGER:2
name_string=EXP:1,SEQUENCE:kdc_principals
[kdc_principals]
princ1=GeneralString:krbtgt
princ2=GeneralString:${ENV::REALM}
```
Create a subordinate CA and sign it's certificate utilizing an earlier-generated ECA's private key
```bash
# generate CSR for the SCA (subordinate CA) (subordinate-ca.conf)
cd ../sca
openssl req -new \
-config olkrb-sca.conf \
-out olkrb-sca.csr \
-keyout private/olkrb-sca.key

# generate SCA
cd ../eca
openssl ca \
-config olkrb-eca.conf \
-in ../sca/olkrb-sca.csr \
-out ../sca/olkrb-sca.crt \
-extensions subordinate_ca_ext
```

Upon Enterprise and subordinate CA creation, obviously, you should store an Enterprise CA related info on an external (isolated) encrypted drive located in a secure environment, consequently removing all related data from a server it was initially created on.



##### Generating service certificates

Create directories for server and client certificates
```bash
mkdir -p /etc/certs/srv/{dsa,kdc}
mkdir -p /etc/certs/clients
```
Next a template for server certificates should be defined
```bash
# /etc/certs/srv/dsa/dsa.conf
[ default ]
SAN = DNS:*.fortress.lan # Default value
[ req ]
default_bits = 2048 # RSA key size
encrypt_key = no # Protect private key
default_md = sha256 # MD to use
utf8 = yes # Input is UTF-8
string_mask = utf8only # Emit UTF-8 strings
prompt = yes # Prompt for DN
distinguished_name = server_dn # DN template
req_extensions = server_reqext # Desired extensions
[ server_dn ]
0.domainComponent = "1. Domain Component (eg, com) "                  # local
1.domainComponent = "2. Domain Component (eg, company) "              # olkrb
2.domainComponent = "3. Domain Component (eg, pki) "                  # 
organizationName = "4. Organization Name (eg, company) "              # OlKrb
organizationalUnitName = "5. Organizational Unit Name (eg, section) " # DSA
commonName = "6. Common Name (eg, FQDN) "                             # dc-1.ops.olkrb.local
commonName_max = 64
[ server_reqext ]
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
subjectAltName = $ENV::SAN
```

During the creation of DSA's CSR remember that slapd requires that a CN of it's certificate should be the FQDN of a server that it runs on, i.e. dc-1.ops.olkrb.local.
```bash
cd /etc/certs/sca
# create server CSR
openssl req -new \
-config ../srv/dsa/dsa.conf \
-out ../srv/dsa/dsa.csr \
-keyout ../srv/dsa/dsa.key

# sign server/client cert
openssl ca \
-config olkrb-sca.conf \
-in ../srv/dsa/dsa.csr \
-out ../srv/dsa/dsa.crt \
-extensions server_ext
```
The same process needs to be repeated for all clients, changing serverAuth to clientAuth and switching the extension from server_ext to client_ext.
Create 2 administrative profiles: `mdb-1_rootdn` and `config_rootdn`.
```bash
grep "Subject:" ../clients/config_rootdn.crt ../clients/mdb-1_rootdn.crt
# ../clients/config_rootdn.crt:        Subject: DC=local, DC=olkrb, O=OlKrb, OU=admin, CN=config_rootdn
# ../clients/mdb-1_rootdn.crt:        Subject: DC=local, DC=olkrb, O=OlKrb, OU=admin, CN=mdb-1_rootdn
```

Later, certificates for the KDC should be generated.


##### CRL generation

For future reference, you can create the CRL to use with KDC, that is, if you have certificates revoked already.
```bash
# revoke a certificate and update the .db file accordingly
openssl ca -config olkrb-sca.conf -revoke 0D.pem -crl_reason superseded

# generate crl
env REALM=/dev/null CLIENT=/dev/null openssl ca -gencrl -config olkrb-sca.conf -out /etc/certs/crl/olkrb-sca.crl -extensions crl_ext
```
It will throw "Revoked certificate while getting initial credentials" if the principal tries to get a TGT using a revoked certificate during the PKINIT flow. 


##### Alternative: Generating certificates without an enterprise CA and use of templates

if you don't feel like making sense out of openssl config files.
First, generate a random value for a PEM passphrase for the key.
```bash
pass generate selfhosted/olkrb/cert/rootca.key
mkdir --parents /etc/certs/{ca,srv,client}
```
Next, generate an RSA key using `openssl` utility and AES256 as it's encryption method.
```bash
openssl genrsa -aes256 -out ca/rootca.key 2048
```
Then, generate an X509 CA certificate with a SHA256 signature (SHA256 is required for the olcTLSCipherSuite used later, otherwise slapd would't launch). You would then be required to store the certificate on every client from which you'd like to perform direct binds (auth).
```bash
openssl req -x509 -new -key ca/rootca.key -sha256 -days 365 -out ca/rootca.pem
```

Following, a private server key with a CSR (certificate sign request) should be generated, and a signed server certificate constructed. Documentation states: "The DN of a server certificate must use the CN attribute to name the server, and the CN must carry the server's fully qualified domain name", so I'll include server's FQDN in the CN of the certificate during the first step. The procedure is as follows:
```bash
openssl req -noenc -newkey rsa:2048 -keyout srv/olkrb.key -out srv/olkrb.csr
openssl x509 -req -days 365 -in srv/olkrb.csr -CA ca/rootca.pem -CAkey ca/rootca.key -CAcreateserial -out srv/olkrb.pem

openssl x509 -in srv/olkrb.pem -text -noout | grep CN
# Subject: C = CA, ST = Ontario, L = Toronto, O = olkrb, OU = ops, CN = dc-1.ops.olkrb.local
```

Finally, generate certificates for administrative clients, that is optional, but I'd prefer it this way. Later, I'll bind these DN's to actual DNs defined by olcRootDN entries of the DBs, so it's a good idea to give these certificates unique and descriptive DNs.
```bash
openssl req -noenc -newkey rsa:2048 -keyout client/mdb-1_rootdn.key -out client/mdb-1_rootdn.csr
openssl x509 -req -days 365 -in client/mdb-1_rootdn.csr -CA rootca.pem -CAkey ca/rootca.key -CAcreateserial -out client/mdb-1_rootdn.pem
openssl x509 -in client/mdb-1_rootdn.pem -text -noout | grep CN
# Subject: C = CA, ST = Ontario, L = Toronto, O = olkrb, OU = ops, CN = mdb-1_rootdn


openssl req -noenc -newkey rsa:2048 -keyout client/config_rootdn.key -out client/config_rootdn.csr
openssl x509 -req -days 365 -in client/config_rootdn.csr -CA ca/rootca.pem -CAkey ca/rootca.key -CAcreateserial -out client/config_rootdn.pem
openssl x509 -in client/config_rootdn.pem -text -noout | grep CN
# Subject: C = CA, ST = Ontario, L = Toronto, O = olkrb, OU = ops, CN = config_rootdn
```


##### Loading certificates

Now, once all necessary prerequisites have been completed, it's time to load the certificates.
First of all, openldap docs state that "If the signing CA was not a top-level (root) CA, certificates for the entire sequence of CA's from the signing CA to the top-level CA should be present. Multiple certificates are simply appended to the file; the order is not significant.". I'll do just that.
```bash
cd /etc/certs
touch sca/olkrb-cas.crt
cat eca/olkrb-eca.crt >> sca/olkrb-cas.crt
cat sca/olkrb-sca.crt >> sca/olkrb-cas.crt
```

Let's adjust the configuration to suit our needs, since slapd.d is being used restarting the daemon is not required, but LDIF-formatted file has to be used to merge with the configuration. I'll set olcTLSVerifyClient to "allow" for now for testing purposes. 
```bash
cat /tmp/tls_srv.ldif
# dn: cn=config
# changetype: modify
# add: olcTLSCertificateKeyFile
# olcTLSCertificateKeyFile: /etc/certs/srv/dsa/dsa.key
# -
# add: olcTLSCertificateFile
# olcTLSCertificateFile: /etc/certs/srv/dsa/dsa.crt
# -
# add: olcTLSCACertificateFile
# olcTLSCACertificateFile: /etc/certs/sca/olkrb-cas.crt
# -
# add: olcTLSCipherSuite
# olcTLSCipherSuite: ECDHE-ECDSA-AES128-GCM-SHA256
# -
# add: olcTLSVerifyClient
# olcTLSVerifyClient: allow

ldapmodify -x -W -H 'ldap://127.0.0.1:389' -D 'cn=config' -f /tmp/tls_srv.ldif
```

Things that are important here:
1) Structure is crutial, i.e. first set of a modify attributes right after the changetype attribute specification and the consequent sets derivided by "-".
1) You might think that attributes should be specified as in documentation (e.g. "TLSCACertificateFile"), but OLC configuration prefix substitution is important here - the attributes should be modified here according to the schema.
2) Make sure slapd has "r" permission bits on required files.
3) The olcTLSCertificateKeyFile attribute should be added BEFORE olcTLSCertificateFile
4) Make sure the key specified with olcTLSCertificateKeyFile is NOT encrypted, as the current slapd implementation is unable to handle key decryption.

In order to make LDAPS work administrative clients should be configured:

TLS_CACERT and TLS_CERT + TLS_KEY will be configured, which are "user-only directives" and can be specified only in user-specific location, i.e. ldaprc. If specified in ldap.conf - clients will fail to send their certificate:
```
65ce865e.0f08d53e 0x7fc8c09fe6c0 TLS trace: SSL3 alert write:fatal:unknown
65ce865e.0f08dfc5 0x7fc8c09fe6c0 TLS trace: SSL_accept:error in error
65ce865e.0f08fd5c 0x7fc8c09fe6c0 TLS: can't accept: error:0A0000C7:SSL routines::peer did not return a certificate.
```
Since the same machine will be used to bind to "cn=config" and "cn=root,dc=ops,dc=olkrb,dc=local" and there are 2 different certificate sets for them - create two files specifying two different client directive structures. And as the TLS_CACERT option is an "equivalent to the server's TLSCACertificateFile option" - include the one-file-joined CA certificate chain here as well.
```bash
echo "TLS_CACERT /etc/certs/sca/olkrb-cas.crt" >> /etc/openldap/ldap.conf
mkdir ~/.config/openldap && touch ~/.config/openldap/ldaprc_{config,mdb-1_rootdn}

cat ~/.config/openldap/ldaprc_mdb-1_rootdn
# TLS_CERT   /etc/certs/mdb-1_rootdn.pem
# TLS_KEY    /etc/certs/mdb-1_rootdn.key

cat ~/.config/openldap/ldaprc_config
# TLS_CERT   /etc/certs/config_rootdn.pem
# TLS_KEY    /etc/certs/config_rootdn.key
```

Additionally, you can specify mechanism and server URI for convenience, later, this article would assume that you did specify these:
```
URI ldaps://dc-1.ops.olkrb.local
SASL_MECH EXTERNAL
```

ldap.conf manual states the "$HOME/$LDAPRC, $HOME/.$LDAPRC, ./$LDAPRC" entries in user config file sourcing procedure. Thus, I can define a simple env switch in one of your shell's source files:
```bash
grep -A 2 '# LDAP' ~/.config/zsh/.zshrc
# LDAP
alias openldapswconf='export LDAPRC=".config/openldap/ldaprc_config"'
alias openldapswroot='export LDAPRC=".config/openldap/ldaprc_mdb-1_rootdn"'
```
Alternatively, I wrote a simple shellscript for that purpose:
```bash
#!/bin/bash

argv=$1
prefix=".config/openldap/"
declare -A list=(
  ["root"]="ldaprc_mdb-1_rootdn"
  ["config"]="ldaprc_config"
)
printarr() { declare -n __p="$1"; for k in "${!__p[@]}"; do printf "%s = %s\n" "$k" "${__p[$k]}" ; done ;  }

set_ldaprc() {
  ldaprc="${prefix}${list[$1]}"
  LDAPRC="${ldaprc}"
  echo LDAPRC=\"$LDAPRC\"
}

case $argv in
  'list')
    printarr list
    ;;
  'root'|'config')
    set_ldaprc $argv
    ;;
  *)
    echo 'Provide the correct argument. "list" to list arguments.'
    ;;
esac
```

Previously, "-x" switch parameter was used, which indicates that the client uses SA (Simple Authentication), now, since that was configured, subsequent interactions with server must be using TLS over LDAPS transport (-H ldaps://dc-1.ops.olkrb.local) (port 636) and thus it should be specified using -Y EXTERNAL (or in ldaprc). It tells server to use SASL/EXTERNAL authc mechanism provided by LDAPs Cyrus SASL package. The SASL/EXTERNAL mechanism enables slapd to use credentials external to authentication method, that is, in this case, TLS.
If EXTERNAL method is not specified, slapd will bind the client in "uid=$USERNAME,cn=$MECHANISM,cn=auth" format, for example:
```
SASL Canonicalize [conn=1001]: authcid="exampleuser"
slap_sasl_getdn: conn 1001 id=exampleuser [len=4]
=> ldap_dn2bv(16)
<= ldap_dn2bv(uid=exampleuser,cn=SCRAM-SHA-512,cn=auth)=0
slap_sasl_getdn: u:id converted to uid=exampleuser,cn=SCRAM-SHA-512,cn=auth
>>> dnNormalize: <uid=exampleuser,cn=SCRAM-SHA-512,cn=auth>
=> ldap_bv2dn(uid=exampleuser,cn=SCRAM-SHA-512,cn=auth,0)
<= ldap_bv2dn(uid=exampleuser,cn=SCRAM-SHA-512,cn=auth)=0
=> ldap_dn2bv(272)
<= ldap_dn2bv(uid=exampleuser,cn=scram-sha-512,cn=auth)=0
<<< dnNormalize: <uid=exampleuser,cn=scram-sha-512,cn=auth>
==>slap_sasl2dn: converting SASL name uid=exampleuser,cn=scram-sha-512,cn=auth to a DN
<==slap_sasl2dn: Converted SASL name to <nothing>
SASL Canonicalize [conn=1001]: slapAuthcDN="uid=exampleuser,cn=scram-sha-512,cn=auth"
SASL [conn=1001] Failure: no secret in database
```
```bash
ldapsearch -Y EXTERNAL -H ldaps://dc-1.ops.olkrb.local -s base '*' +
# OR
ldapsearch -s base '*' +
```

Subsequently, access should be limited to all entries and bind certificates to specific DNs. Keep in mind that: 
1) rootdn's have modify access to all DB entries regardless of what ACLs are present, so you don't have to specify it explicitly.
2) The default behind-the-scenes value of an olcAccess attribute of the config database is "to * by * none", so you can omit it's specification.
Additionally, if you previously had any olcAccess attributes under your main backend database config specification object you can clear it using ldapmodify's delete changetype.

Setting access controls:
```bash
cat /tmp/slapacl-1.ldif
# dn: olcDatabase={1}mdb,cn=config
# changetype: modify
# delete: olcAccess
# -
# add: olcAccess
# olcAccess: {0}to * by * none

ldapmodify -x -W -D 'cn=config' -f /tmp/slapacl-1.ldif
```

Binding client certificates:
```bash
cat /tmp/slapregex-1.ldif /tmp/slapregex-2.ldif
# dn: cn=config
# changetype: modify
# add: olcAuthzRegexp
# olcAuthzRegexp: cn=config_rootdn,ou=admins,o=olkrb,dc=olkrb,dc=local cn=config

# dn: olcDatabase={1}mdb,cn=config
# changetype: modify
# add: olcAuthzRegexp
# olcAuthzRegexp: cn=mdb-1_rootdn,ou=admins,o=olkrb,dc=olkrb,dc=local cn=root,dc=ops,dc=olkrb,dc=local


ldapmodify -x -W -D 'cn=config' -f /tmp/slapregex-1.ldif
ldapmodify -x -W -D 'cn=config' -f /tmp/slapregex-2.ldif
```

Checking if binding is successfull:
```bash
olswconf
LDAPRC=".config/openldap/ldaprc_config"

ldapwhoami -Y EXTERNAL -H ldaps://dc-1.ops.olkrb.local
# SASL username: cn=config_rootdn,ou=admins,o=OlKrb,dc=olkrb,dc=local 
# dn:cn=config


olswroot
LDAPRC=".config/openldap/ldaprc_mdb-1_rootdn"

$ ldapwhoami -Y EXTERNAL -H ldaps://dc-1.ops.olkrb.local
# SASL username: cn=mdb-1_rootdn,ou=admins,o=OlKrb,dc=olkrb,dc=local 
# dn:cn=root,dc=ops,dc=olkrb,dc=local
```

Now, TLSVerifyClient attribute value is safe to be changed to "try" which sets client certificate checking policy, and SA access disabled  completely. As I will use IPC later for the KDC bind, I cannot set it to "demand".
In order to do that I'll need to edit the authz config a little bit.
Usually you'll see the combination of:
```bash
disallow bind_anon
require authc
```
That is disabling anonymous bind and requires the client to supply it's credentials during SA binds, but Simple Authentication needs to be disabled entirely. In order to do it "disallow bind_simple" option needs to be set.
You may noticed the olcDisallows attribute in your schema, it corresponds to the previously mentioned slapd.conf option.
Concequently:
```bash
cat /tmp/dsabind.ldif
# dn: cn=config
# changetype: modify
# add: olcDisallows
# olcDisallows: bind_simple
# -
# replace: olcTLSVerifyClient
# olcTLSVerifyClient: try

ldapmodify -x -W -H 'ldap://dc-1.ops.olkrb.local' -D 'cn=config' -f /tmp/dsabind.ldif
# ldap_bind: Server is unwilling to perform (53)
# additional info: unwilling to perform simple authentication
```



### Preparing Kerberos

Now KRB5 should be prepared, hopefully MIT has [documentation](https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_ldap.html) specifically for it's integration with OpenLDAP.
First step is to add kerberos schema using shipped ldif file. Although the mit-krb5 package was compiled with openldap USE flag the kerberos.openldap.ldif was not created, so I would copy it [from source](https://github.com/krb5/krb5/blob/master/src/plugins/kdb/ldap/libkdb_ldap/kerberos.openldap.ldif), and then add using ldapadd.
```bash
ldapadd -f /path/to/kerberos.openldap.ldif
```

Next step is to create bind DNs for krb5kdc KDC daemon and kadmind service. The MDB database is still empty, so in ldif definitions for the top-level organization object and the rootdn should be included. 
It is not specified which objectClass definitions should be added for kadmind and krb5kdc bind objects and it may look like it should be made out of krbKdcService and krbAdmService object class definitions that kerberos schema provides us with, but they should be of openldap core schema simpleSecurityObject that must have a userPassword attribute for binding, since I, despite my tries, haven't figure out how to make kadmind & krb5kdc to use certificates to bind to openldap. So I'll use these to construct the service accounts.
Some people include objectClass:top during an object definition, however if a class has a "SUP top" in it's olcObjectClasses entry (e.g. it inherits from top) there is no need to explicitly specify it.


I'll generate passwords with the following commands:
```bash
pass generate selfhosted/openldap/kadmind.pass
pass generate selfhosted/openldap/krb5kdc.pass

slappasswd
```

Even tho I will be using IPC, in order for kadmind and krb5kdc to bind to their ldap-stored DNs you CAN configure them to use SASL DIGEST-MD5. This is a challenge-response protocol (similar to NTLM). As in this mechanism ldap server provides user with the challenge and should validate the encrypted response, thus it should have an access to plain-text password, so you store passwords using olcPassword: [CLEARTEXT](CLEARTEXT).
DIGEST-MD5 produces authc id in a form: `uid=<username>,cn=<realm>,cn=digest-md5,cn=auth`, `uid=<username>,cn=digest-md5,cn=auth` with the default realm.
Tho in my case, it would look like this:
```bash
dn: dc=ops,dc=olkrb,dc=local
objectclass: dcObject
objectclass: organization
o: OlKrb
dc: ops

dn: cn=root,dc=ops,dc=olkrb,dc=local
objectclass: organizationalRole
cn: root

dn: ou=service,dc=ops,dc=olkrb,dc=local
ou: service
objectClass: organizationalUnit

dn: cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local
cn: krb5kdc
objectClass: simpleSecurityObject
objectClass: organizationalRole
userPassword: {SSHA}VMehIa5hclQlzZtmJhd6iyHftGn8WHB1

dn: cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local
cn: kadmind
objectClass: simpleSecurityObject
objectClass: organizationalRole
userPassword: {SSHA}2H/occgqspjAmg5E42prgJlpItxsiR10
```

Once initial database entries are defined, you can take a look at the LDAP database that exists so far with the following ldapsearch command:
```bash
ldapsearch -b 'dc=ops,dc=olkrb,dc=local' -s sub '*' +
```

Now, create certificates for the KDC, eigher by using a previously defined template or without it:
```bash
# /etc/certs/srv/kdc/kdc.conf
[ default ]
SAN = DNS:*.fortress.lan # Default value
[ req ]
default_bits = 2048 # RSA key size
encrypt_key = no # Protect private key
default_md = sha256 # MD to use
utf8 = yes # Input is UTF-8
string_mask = utf8only # Emit UTF-8 strings
prompt = yes # Prompt for DN
distinguished_name = server_dn # DN template
[ server_dn ]
0.domainComponent = "1. Domain Component (eg, com) "
1.domainComponent = "2. Domain Component (eg, company) "
2.domainComponent = "3. Domain Component (eg, pki) "
organizationName = "4. Organization Name (eg, company) "
organizationalUnitName = "5. Organizational Unit Name (eg, section) "
commonName = "6. Common Name (eg, FQDN) "
commonName_max = 64
```

I will generate certificates with SAN formatted for pkinit in order to avoid pkinit_eku_checking shenanigans.
```bash
cd /etc/certs/srv/kdc
openssl req -new -config ./kdc.conf -out ./kdc.csr -keyout ./kdc.key
cd /etc/certs/sca
env REALM=OPS.OLKRB.LOCAL CLIENT=/dev/null openssl ca -config olkrb-sca.conf \
-in ../srv/kdc/kdc.csr -out ../srv/kdc/kdc.crt -extensions kdc_ext # I was getting "configuration file routines:str_copy:variable has no value" because of same parameter names in different extensions, so I had to specify the CLIENT envvar even tho it will not be used (e.g. CLIENT=/dev/null)
```

If you will use SA/DIGEST-MD5 or any other password-based authentication mechanism, now you can set passwords to krb5kdc and kadmind binddns using slappasswd utility.
```bash
cat /tmp/krbPassword*
dn: cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local
changetype: modify
add: userPassword
userPassword: {SSHA}VMehIa5hclQlzZtmJhd6iyHftGn8WHB1
dn: cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local
changetype: modify
add: userPassword
userPassword: {SSHA}2H/occgqspjAmg5E42prgJlpItxsiR10

ldapmodify -f /tmp/krbPassword.ldif
ldapmodify -f /tmp/krbPassword1.ldif
```

If you wish to use a template, you can copy/reuse the same template I used earlier for KDC certificate generation, as the majority of a configuration will be in an SCA template extension. 

Now, I will define two configuration files. One is kdc.conf which is for KDC-side client applications such as kadmind and krb5kdc. Second one is krb5.conf, which is for the domain definition.
```bash
export LOCALSTATEDIR="/var/lib"
```
As olcTLSVerifyClient is set to "try" and I've configured certificates I will remove olcRootPW entries for rootdns just in case.



#### KRB5.CONF

Principles will be created with PreAuthentication required by the KDC which prevents AS-REPRoasting and other potential vectors such as Pass-The-* and *-Ticket.
Delegation abuses are also not aplicable here, as it is disabled on KDC-side.
Certificates are signed manually using templates which prevents the whole stack of ADCS-like attacks.

Additionally, the clients will be configured with mandatory PKINIT in mind (mitigates AS-REQRoasting as there are no passwords used).
Additionally, KDC will be configured with mandatory CRL checking to ensure the client certificates're not revoked
KDC and DSA keys will be stored in a safe place to prevent Silver-Ticket attacks for DSA, and Golden/Diamond-Ticket attacks for KDC.
And I will Leave the default encryption types (by default only the AES encryption types are supported)

```bash
[libdefaults]
    default_realm = OPS.OLKRB.LOCAL
[realms]
    OPS.OLKRB.LOCAL = {
        kdc = dc-1.ops.olkrb.local
        admin_server = dc-1.ops.olkrb.local
    }
```


#### KDC.CONF

If I bind to slapd via a root user, ldapi:// (UNIX IPC socket) transport and EXTERNAL authentication mech I will get the following authentication id:
```bash
sudo ldapwhoami -H "ldapi://%2Fvar%2Frun%2Fldapi" -Y EXTERNAL
# dn:gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
```

In "realms", define a realm to create and define a full certificate chain with multiple pkinit_anchors. Finally, specify a KDC certificate with pkinit_identity.
In "dbdefaults" specify a root kerberos container entry DN that will be created later using kdb5_ldap_util.
Finally, in "dbmodules", define required fields such as ldap_kdc_dn and ldap_kadmind_dn, even tho certificates will be used, as I haven't tested if deamons actually work without these options specified. enable account lockout. 
As there is no way for the KDC to use mTLS, I will configure it to use unix sockets (ldapi://), socket file will be open to local system, however, the openLDAP ACLs are kinda restrictive, I will bind specific identities and only let them access the database. I will specify the ldapi connection string with ldap_servers and set the authc mech to EXTERNAL for UNIX sockets usage (ldapi://).
Complete the certificate chain by adding a subordinate CA certificate to the secondary pkinit_anchors. Then, require freshness to prevent domain clients from forging future-times AS-REQ requests that they could reuse later on and that all domain users are in possession of a private key when sending an AS-REQ to the KDC.

Note that you do not want to put non-newline-separated comments in the end of strings inside the kdc.conf, as slapd just sends them "as is" and you'll get the "server is unwilling to perform error.
```
kdb5_ldap_util: Kerberos Container create FAILED: Server is unwilling to perform while creating realm 'OPS.OLKRB.LOCAL'
668ab3ab.20727200 0x7f5975dfc6c0 => ldap_bv2dn(cn=kerberos,dc=ops,dc=olkrb,dc=local # REQ,0)
```
```bash
# /var/lib/krb5kdc/kdc.conf
[kdcdefaults]
  kdc_listen = 88
  kdc_tcp_listen = 88

[realms]
  OPS.OLKRB.LOCAL = {
    kadmind_port = 749
    pkinit_anchors = FILE:/etc/certs/eca/olkrb-eca.crt
    pkinit_anchors = FILE:/etc/certs/sca/olkrb-sca.crt
    pkinit_identity = FILE:/etc/certs/test/kdc.crt,/etc/certs/test/kdc.key
    pkinit_require_freshness = true
    database_module = openldap_ldapconf
    pkinit_require_crl_checking = true
    pkinit_revoke = FILE:/etc/certs/crl/02-olkrb-sca.crl

  }

[logging]
  kdc = FILE:/var/lib/krb5kdc/kdc.log
  admin_server = FILE:/var/lib/krb5kdc/kadmin.log
  debug = true

[dbdefaults]
ldap_kerberos_container_dn = cn=kerberos,dc=ops,dc=olkrb,dc=local

[dbmodules]
  openldap_ldapconf = {
    db_library = kldap
    disable_last_success = true
    disable_lockout = false
    ldap_kdc_dn = "cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local"
    ldap_kadmind_dn = "cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local"
    ldap_servers = ldapi:///
    ldap_kdc_sasl_mech = EXTERNAL
    ldap_kadmind_sasl_mech = EXTERNAL
}
```

Provide kadmind and krb5kdc with access to the realm container. Note that "write" permission bit reads as "wrscdx" meaning that it also contains "read" permission.
```bash
# cat /tmp/k6sRealmContainerAccess.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to dn.subtree="cn=kerberos,dc=ops,dc=olkrb,dc=local"
  by dn.exact="cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local" write
  by dn.exact="cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local" write
  by * none

ldapmodify -f /tmp/k6sRealmContainerAccess.ldif
```

Create the kerberos container, realm object and principle tree. Because the principle subtree will exist underneeth the root entry (cn=kerberos,dc=ops,dc=olkrb,dc=local), -subtree option can be omitted.
I will now add two passwordless, shellless users for the purpose of binding to ldap as two different users, I assume that can be worth it if you have disable_lockout and disable_last_success statements in your kdc.conf file so the krb5kdc and kadmind DNs have different access rights against a kerberos container. I will do it anyways tho.
```bash
useradd -r -m kadmind -s /bin/false
useradd -r -m krb5kdc -s /bin/false

sudo -u kadmind ldapwhoami -H ldapi:/// -Y EXTERNAL
# dn:gidNumber=1001+uidNumber=1001,cn=peercred,cn=external,cn=auth
```
Consequently, I have to bind the AuthcIDs using the olcAuthzRegexp attributes. However, this one's kinda tricky, as this is a RegExp, don't forget to escape the `+` sign, otherwise mapping wouldn't work.
```bash
# incorrect 
olcAuthzRegexp: {2}gidNumber=1001+uidNumber=1001,cn=peercred,cn=external,cn=auth cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local
olcAuthzRegexp: {3}gidNumber=1002+uidNumber=1002,cn=peercred,cn=external,cn=auth cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local
# correct
olcAuthzRegexp: {2}"gidNumber=1001\+uidNumber=1001,cn=peercred,cn=external,cn=auth" "cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local"
olcAuthzRegexp: {3}"gidNumber=1002\+uidNumber=1002,cn=peercred,cn=external,cn=auth" "cn=krb5kdc,ou=service,dc=ops,dc=olkrb,dc=local"
```

As a low privileged, newly created system users are utilized for this task, it is a requirement to add required permissions to these users, I will use ACLs for that. I will grant KDC access to it's certificate and key file, CA public certificates for chain validation. I will grant kadmind access to the kerberos container's master key file.
```bash
setfacl --recursive --modify u:kadmind:rwX /etc/certs/srv/kdc/
setfacl --recursive --modify u:krb5kdc:rwX /var/lib/krb5kdc/
setfacl --modify u:krb5kdc:rw /etc/certs/eca/olkrb-eca.crt
setfacl --modify u:krb5kdc:rw /etc/certs/sca/olkrb-sca.crt

setfacl --modify u:kadmind:r /var/lib/krb5kdc/.k5.OPS.OLKRB.LOCAL
setfacl --modify u:kadmind:rw /var/lib/krb5kdc/kadmin.log
```

As these are unprivileged users, we'll get `Permission denied - Cannot bind server socket on 0.0.0.0.88` error until the required capabilities will be assigned to daemon users. I don't want regular users to have execute rights over a binary with non-standard capabilities, so I will remove this right, these files belong to root:root, so I will just set an ACL for kadmind,krb5kdc users to be able to launch their binaries.
```bash
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/krb5kdc
sudo chmod o-x /usr/sbin/krb5kdc
sudo setfacl --modify u:krb5kdc:x /usr/sbin/krb5kdc

sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/kadmind
sudo chmod o-x /usr/sbin/kadmind
sudo setfacl --modify u:kadmind:x /usr/sbin/kadmind
```

Place principles in a kerberos container. On creation of a kerberos principle always add a requires_preauth flag, here, NFS client principles will be added with the nokey flag, as KDC requires PKINIT usage.
Create an admin account for remote administration, in my case, it is not needed, the same way as kadmind is not needed, but I will just demostrate how to create one:
If you're getting KRB5KDC_ERR_S_PRINCIPAL_UNKNOWN then observe the syslog for a machine principal, entry for which rpc.gssd is searching for in a /etc/krb5.keytab machine keytab.
Btw, keytabs are used here since it doesn't make sense to make machineAccount use PKINIT - it has a randomkey and is not vulnerable AsReqRoasting, and PAC bruteforce
```bash
# set administrative privileges for admin account
echo "admin/admin@ATHENA.MIT.EDU    *" > ./kadm5.acl

# adding principals to the krb database
sudo -u kadmind kadmin.local
# adding an NFS roadwarrior client configured for PKINIT usage
kadmin.local:  addprinc +requires_preauth -nokey rw-msi-1
# adding an admin user
kadmin.local:  addprinc +requires_preauth admin/admin

kadmin.local:  addprinc +requires_preauth -randkey host/rw-msi-1-m.ops.olkrb.local
kadmin.local:  ktadd -k /tmp/krb5.keytab host/rw-msi-1-m.ops.olkrb.local


# Will add the specified key into authorized_keys on the remote machine
ssh-keygen -b 2048 -t rsa -f ~/.ssh/rw-msi-1 -q -N ""
ssh-copy-id -i ~/.ssh/rw-msi-1.pub usr@rw-msi-1-m 
sudo sftp -i ~/.ssh/rw-msi-1 username@rw-msi-1-m

sftp> put /tmp/krb5.keytab
ssh> sudo chown root:root krb5.keytabtmp && sudo mv krb5.keytabtmp /etc/krb5.keytab
```
btw if you want to receive a TGT via just a regular AS-REQ without PA-PK-AS-REQ struct, you can omit -nokey during principal creation and specify the passphrase. Later, when requesting a TGT with kinit, you can omit specifying pkinit_anchors and pkinit_identities for that principal.

kdb5_ldap_util also looks at kdc.conf to fetch the connection uri and the auth mech.
If you wish to authenticate using SA, you would have to remove the `olcDissalows: bind_simple` attribute if you added one and add the following olcAccess attribute as [0](#0) if you have the `to * by * none`:
```bash
olcAccess: {0}to attr=userPassword by anonymous auth
```
Note that if you wished to create a realm under an OU, that will fail with an object class violation.
```
kdb5_ldap_util: Kerberos Container create FAILED: Object class violation while creating realm 'OPS.OLKRB.LOCAL'
668acee6.1331d6a6 0x7f4e137fe6c0 Entry (ou=kerberos,dc=ops,dc=olkrb,dc=local), attribute 'ou' not allowed
```
Additionaly, don't forget that the kdb5_ldap_util should have a capability to create a master key file within the default _var/lib/krb5kdc_.
```bash
sudo kdb5_ldap_util create -D "cn=kadmind,ou=service,dc=ops,dc=olkrb,dc=local" -W -s
```

It should be possible to successfully launch KDC now, additionally make sure it's running upon start.
```bash
sudo -u krb5kdc krb5kdc
sudo -u kadmind kadmind
sudo netstat -tulpn | grep -e kadmind -e krb5kdc
```
If you're using an OpenLDAP backend, but still getting the following error, that probably means that your kdc.conf file formatting is flawed, verify it against a kdc.conf(5).
```
kadmind: Cannot open DB2 database '/var/lib/krb5kdc/principal': No such file or directory while initializing, aborting
```

If your clients' certificate SAN are not PKINIT-standard you can configure pkinit_cert_match attribute under each principle entry to match the format used:
```bash
kadmin.local:  setstr rw-msi-1@OPS.OLKRB.LOCAL pkinit_cert_match <SUBJECT>.*rw-msi-1
```
However, in my case it's not needed since the certificates for PKINIT were generated specifically.


### NFSv4

In NFSv3 there is not room for identity mapping, the server is reporting UID and the UID of the client should match, however, NFSv4 will be used, and it is generally recommended to use NFSv4 with KRB5 authc.

Configure an idmapping domain, as identities in NFSv4 are passed in a form of a username@domain:
```bash
# /etc/idmapd.conf
[General]
Domain = ops.olkrb.local
```

As NFSv4 is a service as KDC sees it, it will be added as a principle via kadmin:
PKINIT flow is only relevant in a context of AS-REQ & AS-REP, so the NFS service would still need to have a keytab entry. Here, omit requires_preauth flag, as a service principal is being created.
It is possible to specify a non-standard krb5.keytab location, however I haven't found options for rpc.svcgssd that will enable to specify the location of a keytab file, so I'll keep it in a default location.
```bash
sudo -u kadmind kadmin.local
kadmin:  addprinc -randkey nfs/dc-1.ops.olkrb.local
kadmin:  ktadd -k /home/kadmind/krb5.keytab nfs/ops.olkrb.local

sudo mv /home/kadmind/krb5.keytab /etc && sudo chown root:root /etc/krb5.keytab
```
For this setup, gssproxy HAS to be running server-side.
```bash
### SERVER-SIDE
cat /etc/gssproxy/24-nfs-server.conf
# [service/nfs-server]
#   mechs = krb5
#   socket = /run/gssproxy.sock
#   cred_store = keytab:/etc/krb5.keytab
#   trusted = yes
#   kernel_nfsd = yes
#   euid = 0

cat gssproxy.conf
# [gssproxy]
#   debug = true
#   debug_level = 3

ls -la /etc/gssproxy
# total 20
# drwxr-xr-x.   2 root root 4096 Jul 20 13:49 .
# drwxr-xr-x. 108 root root 4096 Jul 19 09:08 ..
# -rw-r--r--.   1 root root  200 Jul 20 13:50 24-nfs-server.conf
# -rw-r--r--.   1 root root   44 Jul 12 16:50 gssproxy.conf

sudo rc-service gssproxy start
```

Now, configure an installed-earlier nfs share daemon.
krb5p will be used as an option that will use a service-client shared secret to encrypt the data.
```bash
mkdir -r /export/home
mount --bind /root/home /export/home  # bind a copy of the desired partition to a different place

####################
### /etc/exports ###
####################
/export/home    192.168.1.0/255.255.255.0(no_subtree_check,sec=krb5p)
```
Some usefull options also include, i haven't tested these tho:
1. rw - The client will have read and write access to the exported directory. The default is to allow read-only access.
2. sync - The server must wait until filesystem changes are committed to storage before responding to further client requests. This is the default.


Restart the nfs daemon.
```bash
sudo rc-service nfs restart
```


### firewall

Netfilter on the server is running in deny-incoming mode, I will be using ufw utility as a frontend for it's configuration. Enable Kerberos, as this should be the client-facing service. 
```bash
ufw allow 'Kerberos KDC'
ufw allow NFS
rc-service ufw restart
ufw status verbose
# 88 (Kerberos KDC)          ALLOW IN    Anywhere
```



### Configuring clients

Add a principal that will be provided with a certificate. This principal's username will be mapped against the mounted fs'.
Next, make sure machine's hostname matches it's principal, i.e. for `host/rw-msi-1-m.ops.olkrb.local` and a machine with an interface facing ops.olkrb.local you have to adjust it as follows:
```bash
hostname rw-msi-1-m
useradd -m rw-msi-1
passwd rw-msi-1
```

Generate regular domain client certificates. I'm gonna be reusing the kdc.conf template for initial csr and key generation.
```bash
openssl req -new -config ./kdc.conf -out ../../clients/rw-msi-1.csr -keyout ../../clients/rw-msi-1.key
cd /etc/certs/sca

env REALM=OPS.OLKRB.LOCAL CLIENT=rw-msi-1 openssl ca -config olkrb-sca.conf -in ../clients/rw-msi-1.csr \
-out ../clients/rw-msi-1.crt -extensions krb_client_cert
```

Transfer the certificates using sftp.
```bash
sftp> mkdir crts
sftp> lcd /etc/certs/
sftp> cd crts
sftp> put eca/olkrb-eca.crt
sftp> put sca/olkrb-sca.crt
sftp> put clients/rw-msi-1.crt
sftp> put clients/rw-msi-1.key
```

Set the id mapping domain:
```bash
# /etc/idmapd.conf
[General]
Domain = ops.olkrb.local
```

Add a kerberos flag to nfs-utils in order to get an rpc-gssd executable.
```bash
###################
### package.use ###
###################
net-fs/nfs-utils kerberos
```

Start the rpc-gssd 
```bash
sudo rc-service rpc.gssd start
```
You can also tamper the rpc.gssd init script to include debugging options, which will log into /var/log/syslog:
```bash
#!/sbin/openrc-run

[ -e /etc/conf.d/nfs ] && . /etc/conf.d/nfs
export OPTS_RPC_GSSD="-v -v -v" # same thing for rpc.svcgssd

start() {
        ebegin "Starting gssd"
        start-stop-daemon --start --exec /usr/sbin/rpc.gssd -- ${OPTS_RPC_GSSD}
        eend $?
}
```

configure nfs mount options with sec=krb5p:
```bash
dc-1.ops.olkrb.local:/export/home  /mnt/home  nfs  defaults,sec=krb5p  0 0
```
You can later mount and unmount the remote drive using mount /mnt/home (i.e. specifying the mount point)

Optionally, specify the kerberos realm in a client-side krb5.conf. You can copy the configuration file from host and set pkinit_identities and pkinit_anchors options.
```bash
[libdefaults]
    default_realm = OPS.OLKRB.LOCAL
    dns_lookup_kdc = true
    dns_lookup_realm = false
[realms]
    OPS.OLKRB.LOCAL = {
        kdc = dc-1.ops.olkrb.local
        admin_server = dc-1.ops.olkrb.local
        pkinit_identities = FILE:/home/mlcrp/home/certs/rw-msi-1.crt,/home/mlcrp/home/certs/rw-msi-1.key
        pkinit_anchors = FILE:/home/mlcrp/home/certs/olkrb-eca.crt
        pkinit_anchors = FILE:/home/mlcrp/home/certs/olkrb-sca.crt
}
```
Alternatively, you can provide identities within kinit: `kinit -X X509_user_identity=FILE:/home/mlcrp/home/certs/rw-msi-1.crt,/home/mlcrp/home/certs/rw-msi-1.key -X X509_anchors=FILE:/home/mlcrp/home/certs/olkrb-sca.crt -X X509_anchors=FILE:/home/mlcrp/home/certs/olkrb-eca.crt`


### PoC

How to access file in a share from a different machine? As NFSv4 is used uid do not have to match, username mapping is in use. That way, full client identity separation capabilities are provided as if the mounted FS was on a partition of a physically accessible disk.
```bash
###################
### SERVER-SIDE ###
###################
echo "smth" | tee smth.txt
sudo chown rw-msi-1:rw-msi-1 smth.txt && sudo chmod 0700 smth.txt
grep -e rw-msi-1 /etc/passwd
# rw-msi-1:x:1003:1003::/home/rw-msi-1:/bin/bash


###################
### CLIENT-SIDE ###
###################
sudo mount /mnt/home # will make a machine TGT request automatically (i.e. like `kinit -k -t /etc/krb5.keytab`)
su rw-msi-1

cd ~/crts
kinit -X X509_user_identity=FILE:rw-msi-1.crt,rw-msi-1.key -X X509_anchors=FILE:olkrb-eca.crt -X X509_anchors=FILE:olkrb-sca.crt
```
GSSAPI has a concept called ccache (cc) which is a file used to store TGT and (i assume) TGS for a principal. default locations for userAccounts are /tmp/krb5cc_%U where %U is a UID. klist list the ccache for a calling principal:
```bash
klist
# Ticket cache: FILE:/tmp/krb5cc_1002
# Default principal: rw-msi-1@OPS.OLKRB.LOCAL

# Valid starting       Expires              Service principal
# 07/20/2024 15:37:08  07/21/2024 15:37:08  krbtgt/OPS.OLKRB.LOCAL@OPS.OLKRB.LOCAL

cat smth.txt
# smth

grep -e rw-msi-1 /etc/passwd
# rw-msi-1:x:1002:1002::/home/rw-msi-1:/bin/bash
```
