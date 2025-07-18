# UEFI
## EFI shell
Installing EFI shell:
```bash
### the standard EFI boot binary location is /efi/boot/bootx64.efi
mount /dev/sdb1 /efi && cd /efi
mkdir EFI/boot && cd EFI/boot
wget https://github.com/tianocore/edk2/raw/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi -O bootx64.efi
```

Usage:
```
# show mapping table
map

# set directory to storage device
$DEVICE_NAME:
# e.g.
FS0:

# load an EFI driver
load ./bin.efi

# execute a binary
./path/to/bin
```
