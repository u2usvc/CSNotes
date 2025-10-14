# android

## adb

### connect

```bash
### GENERAL
adb start-server                      # start the daemon
# then on the phone accept the debugging from 
# a specific server (on a device with dev mode and usb debugging enabled)
adb shell                             # enter shell with the connected device
adb devices                           # list connected devices
```

### basic usage

```bash
### FILE TRANSFER
adb push $LOCAL_PATH $REMOTE_PATH     # push files/directories to android device (add trailing slash to push contents of dir)
adb pull $REMOTE_PATH                 # pull files/directories from android device

### backup
adb backup -apk -noshared -all -f backup-full.adb
adb restore backup-full.adb

# list services
service list

# elevate to root (accept the prompt)
adb root
```

### packages

```bash
# list
cmd package list packages
### (UN)INSTALL
adb install com.android.custom.apk    # install custom APK
pm uninstall $PACKAGE                 # uninstall package (use -k to keep app files and cache)
# OR IF THE ABOVE ERRORS OUT
adb uninstall --user 0 $PACKAGE

# reinstal system package
cmd package install-existing $PACKAGE

# query all permissions for a package
appops get me.zhanghai.android.files

# disable package ???
pm disable $PACKAGE
```

## fastboot

```bash
# reboot to bootloader
adb -d reboot bootloader

# list connected devices
fastboot devices

fastboot flashing unlock 

# display all vars
fastboot getvar all

# manufacturer-specific
fastboot oem
```

## adbsync

- [better-adb-sync](https://github.com/jb2170/better-adb-sync)

```bash
adbsync push /home/fuser/docs/ /storage/emulated/0/Documents/docs/
```

## termux

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

### integrate nvim yank/paste with system clipboard

- install Termux-API and follow the setup instructions
- `pkg install termux-api`
