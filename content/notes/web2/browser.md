# Browser

## Node

### node inspector devtools abuse

```bash
### Scenario: root is running node inspector
# root        1390  0.0  1.2 1066896 48332 ?       Ssl  08:27   0:02 /usr/bin/node --inspect=127.0.0.1:9229 /opt/uptime-monitor/worker.js

# create an ssh tunnel
ssh -L 9229:127.0.0.1:9229 user@10.129.245.214
```

Chromium > `chrome://inspect` > add remote target `localhost:9229` > inspect > Console
