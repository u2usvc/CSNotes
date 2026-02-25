# BGP

## eBGP

### MT ROS setup

```bash
# make router-id a local router loopback address (optional)
# remote.as if not specified will be automatically determined
/routing/bgp/connection/add name=bgp-65100 as=65200 router-id=10.0.0.3 remote.address=38.65.83.201 remote.as=65100 local.role=ebgp local.address=20.84.87.139 connect=yes listen=yes
# now, mirror this config for 2nd router (AS 65100) and the entry should appear under:
/routing/bgp/session/print

# eBGP functions now, but doesn't do anything
# in order for you and your eBGP to actually learn some routers from the remote network you need to configure routers on both peers (e.g. on both AS') to contain the "output.network" setting.
/routing/bgp/connection/set numbers=0 output.network=bgp-65100-out
/ip/firewall/address-list/add list=bgp-65100-out address=10.3.1.0/24
/ip/firewall/address-list/add list=bgp-65100-out address=10.3.2.0/24
# try to check /ip/route/print on the AS65100 router, you should learn routes you advertised here
# now, mirror this config for the 2nd router (AS 65100) and set the required routes for it to advertise to the AS65200 router
```
