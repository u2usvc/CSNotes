# DNS

## DoH

### MT ROS setup

```bash
# set the cloudflare server ("servers" is to resolve the DoH server itself, use-doh-server is a DoH server address)
# after DoH server address is resolved all other DNS requests will be made via DoH
/ip/dns/set verify-doh-cert=yes allow-remote-requests=yes doh-max-concurent-queries=100 doh-max-server-connections=20 doh-timeout=6s servers=1.1.1.1 use-doh-server=https://cloudflare-dns.com/dns-query

# fetch the downloaded cert chain
/tool/fetch url=http://192.168.60.1:9595/one-one-one-chain.pem
/file/print

/certificate/import file-name=one-one-one-chain.pem
# certificates-imported: 3
```

## Misc

### MT ROS update static DNS entries from DHCP

```bash
/system/script/add name=update-dns-from-dhcp policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive source="
:local domain ".aperture.ad";
:local leases [/ip dhcp-server lease find dynamic=yes];

:foreach i in=[/ip dns static find where name~$domain] do={
    /ip dns static remove $i;
}

:foreach i in=$leases do={
    :local hostname [/ip dhcp-server lease get $i host-name];
    :local address [/ip dhcp-server lease get $i address];

    :if ([:len $hostname] > 0) do={
        :local fqdn ($hostname . $domain);
        /ip dns static add name=$fqdn address=$address ttl=5m comment="From DHCP lease";
    }
}
"

/system scheduler add name=update-dns-from-dhcp interval=5m on-event="/system script run update-dns-from-dhcp"
```
