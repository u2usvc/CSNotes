---
title: "Detecting classic and fileless secretsdump"
date: 2026-08-14
description: "Detecting classic (RegSaveKey) and fileless (RegQueryValue) techniques for dumping SAM/SECURITY hive contents over RPC MS-RRP / SMB"
tags: ["sys"]
---

## Technique description

So this week I saw a recent discussion related to this pull request <https://github.com/fortra/impacket/pull/1698/changes> online (I know, it's really old) and I thought to myself that surely it is no different from classic secretsdump when it comes to core events generated.

## Preparation note

So the general idea is as follows:

1) You should already have SACL for SAM and SECURITY hives (GPO) (e.g. `"Everyone","ReadKey,ChangePermissions,TakeOwnership","ContainerInherit","None","Success,Failure"`)
2) You should have audit enabled (GPO)
3) You probably should filter out events from `S-1-5-18`, because it generates too much noise (fleet server)

## Telemetry differences between classic and `-inline`

### Classic

Let's take the classic variant:

![Secretsdump classic](/images/08-15_secretsdump01.png)

- 4672 "Special privileges assigned to new logon"

- 4624 "An account was successfully logged on"

- 5140 "A network share object was accessed" > `\\*\IPC$`

- 5145 "A network share object was checked to see whether client can be granted desired access" > `\\*\IPC$\svcctl`

- 4674 "An operation was attempted on a privileged object." >

```txt
An operation was attempted on a privileged object.

Subject:
  Security ID:    S-1-5-21-140293804-2557303691-3365525282-500
  Account Name:    Administrator
  Account Domain:    DET
  Logon ID:    0x9C568F1

Object:
  Object Server:  SC Manager
  Object Type:  SERVICE OBJECT
  Object Name:  RemoteRegistry
  Object Handle:  0xffffdf84b1e82810

Process Information:
  Process ID:  0x238
  Process Name:  C:\Windows\System32\services.exe

Requested Operation:
  Desired Access:  DELETE
        READ_CONTROL20
        WRITE_DAC
        Query service configuration information
        Set service configuration information
        Query status of service
        Enumerate dependencies of service
        Start the service
        Stop the service
        Pause or continue the service
        Query information from service
        Issue service-specific control commands
        
  Privileges:    SeTakeOwnershipPrivilege
```

- 4688 "A new process has been created" > `C:\Windows\system32\svchost.exe -k localService -p -s RemoteRegistry`

- 7036 "The Remote Registry service entered the running state"

- 5145 "A network share object was checked to see whether client can be granted desired access" > `\\*\IPC$\winreg`

- 5140 "A network share object was accessed" > `\\*\ADMIN$`

- 5145 "A network share object was checked to see whether client can be granted desired access" x2 > ReadData `\\*\ADMIN$\Temp\$RANDOM_NAME.tmp`

Wrapping up:

- 7036 "The Remote Registry service entered the stopped state"

- 5145 "A network share object was checked to see whether client can be granted desired access" > `\\*\IPC$\samr`

- 5145 "A network share object was checked to see whether client can be granted desired access" x2 > DELETE `\\*\ADMIN$\Temp\$RANDOM_NAME.tmp`

- 4634 "An account was logged off"

### Inline

![Elastic 02](/images/08-15_inline03.png)

It starts with similar telemetry as before, but after 5145 to `\\*\IPC$\winreg`, we are getting a loop with:

- 4673 "A privileged service was called" > `C:\Windows\System32\svchost.exe` SeTcbPrivilege
- 4670 "Permissions on an object were changed" > ACE with `KEY_QUERY_VALUE` and `KEY_ENUMERATE_SUB_KEYS` was added to `BUILTIN\Administrators` against

```python
keys = [r'SAM\SAM', r'SAM\SAM\Domains', r'SAM\SAM\Domains\Account', r'SAM\SAM\Domains\Account\Users', r'SECURITY\Policy\Secrets', r'SECURITY\Policy\Secrets\NL$KM', r'SECURITY\Policy\Secrets\NL$KM\CurrVal', r'SECURITY\Cache', r'SECURITY\Policy\PolEKList', r'SECURITY\Policy\PolSecretEncryptionKey']
```

![Elastic 03](/images/08-15_inline02.png)


## Detection rules

Each access attempt will generate event 4656 (A handle to an object was requested).

```yaml
title: SAM Or SECURITY Hive Read By A Non-SYSTEM Principal
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID:
            - 4656
        ObjectType: 'Key'
        ObjectName|startswith:
            - '\REGISTRY\MACHINE\SAM'
            - '\REGISTRY\MACHINE\SECURITY'
    filter_system:
        SubjectUserSid: 'S-1-5-18'
    condition: selection and not filter_system
level: high
```

A few events in case we're performing a classic dump:

![Elastic 01](/images/08-15_sam.png)

And a lot more if we're doing an `-inline` dump:

![Elastic 02](/images/08-15_inline.png)

Also, because `winlog.event_data.SubjectUserSid` in 4656 doesn't populate `user.id`, you might need to add a custom ingest pipeline.

```json
[
  {
    "set": {
      "field": "user.id",
      "copy_from": "winlog.event_data.SubjectUserSid",
      "if": "ctx.user?.id == null && ctx.winlog?.event_data?.SubjectUserSid != null"
    }
  }
]
```
