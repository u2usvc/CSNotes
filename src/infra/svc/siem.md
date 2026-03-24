# SIEM

## Collection

### Sysmon

#### setup via GPO

Create a directory in DC SYSVOL share.
SYSVOL is readable by all users by default.
`\\<DC>\SYSVOL\<FQDN>\Sysmon\` (check in `net share`, SYSVOL share should be under `C:\Windows\SYSVOL\sysvol\`)

It should hold

- `Sysmon64.exe`
- `sysmonConfig.xml`
- `deploy_sysmon.bat`

`deploy_sysmon.bat` in the same SYSVOL Sysmon folder:

```bat
@echo off

SET DC=WIN-DC02              # CHANGEME
SET FQDN=SALES.CONTOSO.LAB   # CHANGEME

IF EXIST "C:\Program Files (x86)" (
    SET BINARCH=Sysmon64.exe
    SET SERVBINARCH=Sysmon64
) ELSE (
    SET BINARCH=Sysmon.exe
    SET SERVBINARCH=Sysmon
)

SET SYSMONDIR=C:\Windows\Sysmon
SET SYSMONBIN=%SYSMONDIR%\%BINARCH%
SET SYSMONCONFIG=%SYSMONDIR%\sysmonConfig.xml
SET GLBSYSMONBIN=\\%DC%\SYSVOL\%FQDN%\Sysmon\%BINARCH%
SET GLBSYSMONCONFIG=\\%DC%\SYSVOL\%FQDN%\Sysmon\sysmonConfig.xml

:: Check if Sysmon service is running
sc query "%SERVBINARCH%" | Find "RUNNING"
If "%ERRORLEVEL%" EQU "1" (
    goto startsysmon
)
:: If running, just update config
goto updateconfig

:installsysmon
IF NOT EXIST %SYSMONDIR% (
    mkdir %SYSMONDIR%
)
xcopy %GLBSYSMONBIN% %SYSMONDIR% /y
xcopy %GLBSYSMONCONFIG% %SYSMONDIR% /y
chdir %SYSMONDIR%
%SYSMONBIN% -i %SYSMONCONFIG% -accepteula -h md5,sha256 -n -l
sc config %SERVBINARCH% start= auto
EXIT /B 0

:updateconfig
xcopy %GLBSYSMONCONFIG% %SYSMONCONFIG% /y
chdir %SYSMONDIR%
%SYSMONBIN% -c %SYSMONCONFIG%
EXIT /B 0

:startsysmon
sc start %SERVBINARCH%
If "%ERRORLEVEL%" EQU "1060" (
    goto installsysmon
) ELSE (
    goto updateconfig
)
```

GPO:

`Computer Configuration > Windows Settings > Scripts (Startup/Shutdown)`
`Add > in Script Name, enter the full UNC path`
`\\<DC>\SYSVOL\<FQDN>\Sysmon\deploy_sysmon.bat`
