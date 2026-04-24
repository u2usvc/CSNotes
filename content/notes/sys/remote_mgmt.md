# Remote management

## Windows

### PsExec

```bash
impacket-psexec contoso.lab/Administrator:'P@$$wd!'@192.168.1.21
# Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies
# 
# [*] Requesting shares on 192.168.1.21.....
# [*] Found writable share ADMIN$
# [*] Uploading file aoagcXeE.exe
# [*] Opening SVCManager on 192.168.1.21.....
# [*] Creating service rGEg on 192.168.1.21.....
# [*] Starting service rGEg.....
# [!] Press help for extra shell commands
# Microsoft Windows [Version 10.0.14393]
# (c) 2016 Microsoft Corporation. All rights reserved.
# 
# C:\Windows\system32>
```
