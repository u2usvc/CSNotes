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

### RDP

#### Setup

```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### WinRM

#### pwsh

##### Execution

```powershell
### 1) SIMPLE CONNECT
Enter-PSSession -ComputerName $HOST -Credential (Get-Credential)

### 2) SIMPLE CONNECT
$pscred = Get-Credential
# OR
$secPass = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
New-Object System.Management.Automation.PSCredential ($USERNAME, $secPass)


# invoke-command on multiple machines
Invoke-Command -Session $MULTIPLE_SESSION_OBJECT -ScriptBlock { $COMMAND }


### GNU/Linux pwsh
# ensure PSWSMan is installed
Get-InstalledModule | Where-Object {$_.Name -match 'pswsman'}
# if not - install it
pwsh -Command 'Install-Module -Name PSWSMan'
sudo pwsh -Command 'Install-WSMan'
# ENSURE CAPITAL LETTERS
$serviceUserName = 'Administrator@CONTOSO.ORG'; $servicePassword = 'win2016-cli-P@$swd'; $secStringPassword = ConvertTo-SecureString $servicePassword -AsPlainText -Force; $credObject = New-Object System.Management.Automation.PSCredential ($serviceUserName, $secStringPassword);
# WARNING! -Computer <IP ADDR> cannot be used with -Authentication Kerberos (only with Basic and Negotiate (NTLM))
# ENSURE computer name is resolvable
Enter-PSSession -Computer WIN-KML6TP4LOOL.CONTOSO.ORG -Credential $credObject -Authentication Kerberos
```

#### pywinrm

```bash
# python
import winrm
session = winrm.Session('192.168.68.72', auth=('administrator','win2016-cli-passwd'), transport='ntlm')
session.run_ps("whoami").std_out
```

#### quickconfig

```powershell
# that would be enough to fully enable WinRM over HTTP on the host
winrm quickconfig

# display service config (info on ports used, authentication methods available)
winrm get winrm/config

# test winrm availability (on winrm-enabled machine)
Test-WSMan
```
