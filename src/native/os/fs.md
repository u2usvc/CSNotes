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

## mount qcow2

```bash
guestfish -a $FILE.qcow2
> run
> list-filesystems

guestmount -a $FILE.qcow2 -m /dev/vg0/root /mnt/
cd /mnt/

# umount
guestunmount $MOUNT_POINT
```

## RAID-Z quickstart

```bash
ls -la /dev/disk/by-id
# lrwxrwxrwx  1 root root   9 Sep 29 03:34 wwn-0x5000c5005ac3368e -> ../../sdb
# lrwxrwxrwx  1 root root   9 Sep 29 03:34 wwn-0x5000c500a20704c9 -> ../../sdc
# lrwxrwxrwx  1 root root   9 Sep 29 03:34 wwn-0x5000c500be464151 -> ../../sda

# create raidz1 pool
sudo zpool create tank -f raidz wwn-0x5000c5005ac3368e wwn-0x5000c500a20704c9 wwn-0x5000c500be464151

sudo zpool status
#   pool: tank
#  state: ONLINE
# config:
# 
#         NAME                        STATE     READ WRITE CKSUM
#         tank                        ONLINE       0     0     0
#           raidz1-0                  ONLINE       0     0     0
#             wwn-0x5000c5005ac3368e  ONLINE       0     0     0
#             wwn-0x5000c500a20704c9  ONLINE       0     0     0
#             wwn-0x5000c500be464151  ONLINE       0     0     0
# 
# errors: No known data errors
```

```bash
# create an FS on pool and mount it
sudo zfs create -o mountpoint=/data tank/data

sudo zfs list
```

### Migration

```bash
# on a source system list features of the pool
zpool get all $POOL_NAME | grep feature@
# on a target system ensure that all pool features are supported by ZFS
zpool upgrade

# discover available pools
zpool import

# import existing pool
zpool import $POOL -f
```
