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
