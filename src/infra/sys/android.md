# Android

## termux

### Setup

```bash
# enable storage access
termux-setup-storage    # this will create a symlink set to /storage/emulated/** in termux home dir
ls ~/storage/shared

### white cursor
# Android => Settings => Dark Mode settings => disable dark mode for Termux
echo "cursor= #FFFFFF" > ~/.termux/colors.properties
termux-reload-settings

### git
# write ~ path in .ssh/config
# ensure .ssh/config is 600
echo '192.168.1.69 dc-1.aisp.aperture.local' >> ~/.hosts
echo "HOSTALIASES=~/.hosts" > ~/.bashrc
wget g -O /dev/null
```

Termux url opener example (executes on url share). This file should be stored under `$HOME/bin/termux-url-opener`

### integrate nvim yank & paste with system clipboard

- install Termux-API and follow the setup instructions
- `pkg install termux-api`
