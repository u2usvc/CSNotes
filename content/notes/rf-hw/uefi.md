# UEFI

## EFI shell

### Installation

Installing EFI shell:

```bash
### the standard EFI boot binary location is /efi/boot/bootx64.efi
mount /dev/sdb1 /efi && cd /efi
mkdir EFI/boot && cd EFI/boot
wget https://github.com/tianocore/edk2/raw/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi -O bootx64.efi
# where /dev/sdb1 must be fat32 formatted partition with "efi system" gpt label
# make sure no other efi/boot/bootx64.efi binaries are present on other partitions
```

### Usage

```bash
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
