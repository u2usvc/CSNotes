# FS

## NTFS

### ntfs-3g

#### Troubleshooting

```bash
# format
mkfs.ntfs -Q /dev/sdyX

# mount 
mount -t ntfs-3g /dev/device /path/to/mountpoint
```

Fix dirty flag:

```bash
# dirty flag is set
sudo ntfsinfo -mf /dev/sdb1 | grep -iE 'dirty|flag|state'
# WARNING: Dirty volume mount was forced by the 'force' mount option.
#         Device state: 11
#         Volume State: 91
#         Volume Flags: 0x0001 DIRTY
#         State of FILE_Bitmap Inode: 80
#         Attribute State: 3

# remove the dirty flag (dangerous)
sudo ntfsfix -d /dev/sdb1
# Mounting volume... OK
# Processing of $MFT and $MFTMirr completed successfully.
# Checking the alternate boot sector... OK
# NTFS volume version is 3.1.
# NTFS partition /dev/sdb1 was processed successfully.

# check if mount works
sudo mount -t ntfs-3g /dev/sdb1 ~/ntfs
sudo umount ~/ntfs

# check if dirty volume is absent
sudo ntfsinfo -m /dev/sdb1
# Volume Information
#         Name of device: /dev/sdb1
#         Device state: 11
#         Volume Name:
#         Volume State: 91
# ...
```
