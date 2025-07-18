# FW RE
## binwalk
```bash
# recursive extract
binwalk -Me 01-00000010-U00000010.bin

# attempt to extract each datatype from it's starting address to it's ending address
ls -l _01-00000010-U00000010.bin.extracted
```

## extract Lnux from zImage compressed with LZMA
[vmlinux-to-elf](https://github.com/marin-m/vmlinux-to-elf)
```bash
./vmlinux-to-elf <input_kernel.bin> <output_kernel.elf>
```

## mount jffs2, because binwalk is unable to
[mount.jffs2](https://github.com/fwhacking/mount.jffs2/blob/9fe8db976f672383a65dee81a8e02c249307a9f6/mount.jffs2)
```bash
  binwalk -Mqe 01-00000024-U00000024.bin

  cd _01-00000024-U00000024.bin.extracted/_0.extracted

  mkdir jffs2_root

  sudo mount.jffs2 0.jffs2 jffs2_root
  # Sanity check passed...
  # Image 0.jffs2 sucessfully mounted on jffs2_root

  cd jffs2_root && ls
  # bin  cfez.bin  config  lib  Megafon  webroot
```

## unpack android bootimg
[android-unpackbootimg](https://github.com/anestisb/android-unpackbootimg)
```bash
mkdir kernel && unpackbootimg -i 03-00030000-Kernel.bin -o kernel && cd kernel
# Android magic found at: 128
# BOARD_KERNEL_CMDLINE root=/dev/ram0 rw console=ttyAMA0,115200 console=uw_tty0,115200 rdinit=/init loglevel=5 mem=0x9200000
# BOARD_KERNEL_BASE 55e08000
# BOARD_NAME
# BOARD_PAGE_SIZE 2048
# BOARD_HASH_TYPE sha1
# BOARD_KERNEL_OFFSET 00008000
# BOARD_RAMDISK_OFFSET 01000000
# BOARD_SECOND_OFFSET 00f00000
# BOARD_TAGS_OFFSET 00000100
```

## Huawei
[balongflash](https://github.com/forth32/balongflash)

[About Huawei LTE routers](https://github.com/Huawei-LTE-routers-mods/README/blob/master/README.md)

[4PDA](https://4pda.to/forum/index.php?showtopic=744265)

[AT commands](https://4pda.to/forum/index.php?showtopic=582284)
