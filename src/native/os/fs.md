# FS

## cryptsetup

```bash
#############
### SETUP ###
#############
# first partition the drive

# encrypt the partition scheme (uses aes-xts-plain64 by default)
cryptsetup luksFormat /dev/sdc1

# decrypt
cryptsetup open /dev/sdc1 my_device

# create a filesystem
mkfs.btrfs /dev/mapper/my_device


#############
### USAGE ###
#############
### MOUNT
# decrypt
cryptsetup open /dev/sdc1 my_device
# mount
mount /dev/mapper/my_device /mnt/sdc1

# ! cp & pt
sudo cryptsetup open /dev/sda1 my_device && sudo mount /dev/mapper/my_device /mnt/sda1

### UNMOUNT
# unmount
umount /mnt/sdc1
# reencrypt
cryptsetup close my_device

# ! cp & pt
sudo umount /mnt/sda1 && sudo cryptsetup close my_device
```

## disk clone (nasty)

```bash
### it's better to replicate the GPT using fdisk and then use dd partition-by-partition

dd if=/dev/sda of=/dev/sdb bs=32M status=progress
# fix problems (e.g. if target drive was smaller -> create the destroyed last-sector (backup) GPT)
gdisk /dev/sdb
v # verify disk
x # enter expert's menu
e # realocate backup data structures at the end of the disk
m # return to main mode
d # delete last partition as it doesn't fit
3
w # write changes
```

## secure HDD wipe

```bash
shred --verbose --random-source /dev/urandom --iterations 1 /dev/sda
```

## useful

### overwrite drive with zero bites

```bash
dd if=/dev/zero of=/dev/sdX bs=1M
```

### determine what process is making a target busy during umount (preventing the umount)

```bash
fuser -mv $MOUNT_POINT          # fuser -mv /mnt/sda1
```

### mount

```bash
mount --rbind [ORIG_PARTITION] [TARGET_PARTITION] # Remount existing partition into different place

mount --bind $ORIG_MOUNT_POINT $COPY_MOUNT_POINT  # bind a copy of one partition to a different place

# remount fs read-write:
mount -o remount,rw /mount/point                  # e.g. mount -o remount,rw /dev/sda1
```

### burden the iso

```bash
sudo su
cat $PATH_TO_ISO > $DRIVE_PATH              # By-id! /dev/disk/by-id/usb-General_UDisk-0\:0
```

## fdisk

```bash
sudo fdisk /dev/sda

m      # to display help
g      # new GPT label
n      # create new partition
w      # write and exit
```

## ntfs

```bash
# install ntfs-3g
emerge --ask sys-fs/ntfs3g

# format
mkfs.ntfs -Q /dev/sdyX

# mount 
mount -t ntfs-3g /dev/device /path/to/mountpoint
```

## btrfs

```bash
# create snapshot
btrfs subvolume snapshot $SVOL $SNAPSHOT

# restore snapshot
sudo btrfs subv delete $SVOL
btrfs subv snapshot $SNAPSHOT $SVOL

# scrub subvolume
btrfs scrub start $SVOL

# balance subvolume
btrfs balance start -musage=50 -dusage=50 $SVOL
```
