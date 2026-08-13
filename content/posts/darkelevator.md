---
title: "DarkElevator traces"
date: 2026-08-01
description: "Quickstart and sigma for CVE-2026-50343 (DarkElevator) Windows CrossDevice LPE"
---
Posts
## Vulnerability description

- Affected: windows 11 (CrossDevice only present on win11)
- Prerequisites: unprivileged account shell
- Impact: LPE to SYSTEM
- PoC: <https://github.com/califio/publications/tree/main/MADBugs/windows-CVE-2026-50343>

Exploitation of CVE-2026-50343 (DarkElevator) LPE can be detected by looking for value events under `StaticPluginMap` that have CLSID as a value.
Posts
InstallService runs as SYSTEM and resolves plugins by reading a pluginID with CLSID value from `StaticPluginMap` key, it then instantiates COM class via `CoCreateInstance` with InprocServer of that CLSID.

We can see here that CrossDevice CLSID InprocServer32 points to a DLL under `%PROGRAMDATA%\CrossDevice\`

![CrossDevice path](/images/crossdevice.png)

`%PROGRAMDATA%` directory is user-writable, so an attacker can write a malicious DLL there, if it doesn't exist already (which it doesn't, by default), which will get loaded into InstallService process (upon each DLL load `DllMain` is triggered)

![CrossDevice path](/images/streaming_dll.png)

## Detection

Unfortunately, I wasn't able to determine legitimate cases of writing CLSID mapping to `StaticPluginMap`, but what I did determine, is that none of my windows desktop machines have any values present there.
Because of this, I will conclude that no legitimate writes will happen, that is why exploitation can be detected by looking for value events under `StaticPluginMap` that have CLSID as a value.

```yaml
title: Dark Elevator
logsource:
  product: windows
  service: sysmon
detection:
  plugin_map:
    EventID: 13
    TargetObject|contains: 'StaticPluginMap'
    Details|startswith: '{'
  condition: plugin_map
```

![Detect](/images/detect01.png)
