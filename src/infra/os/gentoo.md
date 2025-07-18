# gentoo
#### About

[doc: gentoo](https://wiki.gentoo.org/wiki/Full_Disk_Encryption_From_Scratch)
1. Passwords and keys protect keyslots on the LUKS header, which contains the master key that actually encrypts the partition data.
2. The header file must be kept safe. If the header file is lost, all data on the LUKS partition it secured will be irrecoverable.
3. For this, use system with the same kernel as target system
4. This setup will require the usage of initramfs, because there should be a pre-fs to decrypt the primary fs.


#### Process

- download the "minimal installation CD" from here: [https://www.gentoo.org/downloads/](https://www.gentoo.org/downloads/)
- burden it with cat
- boot with the ethernet cable connected
- partition as told here: [https://wiki.gentoo.org/wiki/Full_Disk_Encryption_From_Scratch#Disk_preparation](https://wiki.gentoo.org/wiki/Full_Disk_Encryption_From_Scratch#Disk_preparation)
```bash
### PARTITION AS FOLLOWS (see gentoo doc link)
# sda1 will hold GRUB
# sda2 will hold luks header and initramfs
# if a keyfile will be encrypted ASYMMETRICALLY, yubikey smartcard can be used
/dev/sda
├── /dev/sda1      [EFI]   /efi      1 GB         fat32       Bootloader
└── /dev/sda2      [BOOTX] /boot     1 GB         ext4        Bootloader support files, kernel and initramfs
/dev/nvme0n1
└── /dev/nvme0n1p1 [ROOT]  (root)    ->END        luks        Encrypted root device, mapped to the name 'root'
└──  /dev/mapper/root /         ->END        btrfs       root filesystem
/home     subvolume                Subvolume created for the home directory
/var      subvolume                Subvolume created for the var directory
/etc      subvolume                Subvolume created for the etc directory
```

- encrypt the fs
```bash
### IF YOU WANT TO USE SMARTCARD / YUBIKEY USE ASYMMETRIC ENCRYPTION INSTEAD
# GPG Symmetrically Encrypted Key File (don't forget to move it to boot drive later):
dd bs=8388608 count=1 if=/dev/urandom | gpg --symmetric --cipher-algo AES256 --output crypt_key.luks.gpg
# Secure the partition using a GPG protected key file:
gpg --decrypt crypt_key.luks.gpg | cryptsetup luksFormat --key-size 512 /dev/nvme0n1p1 -
# backup header file (don't forget to move it to separate drive)
cryptsetup luksHeaderBackup /dev/nvme0n1p1 --header-backup-file crypt_headers.img
# mount the encrypted root:
export GPG_TTY=$(tty)
sudo gpg --decrypt crypt_key.luks.gpg | sudo cryptsetup --key-file - open /dev/nvme0n1p1 root
```

- mount root and format drives
```bash
### FORMAT AS FOLLOWS:
# boot drive:
mkfs.vfat -F32 /dev/sda1
# make ext4 fs with "boot" label
mkfs.ext4 -L boot /dev/sda2

# root drive (if btrfs) with "rootfs" label
mkfs.btrfs -L rootfs /dev/mapper/root

# format root drive (if btrfs (if not btrfs - create as separate partitions))
mount LABEL=rootfs /mnt/gentoo
btrfs subvolume create /mnt/gentoo/etc
btrfs subvolume create /mnt/gentoo/home
btrfs subvolume create /mnt/gentoo/var
```
- obtain stage tarball & unpack
```bash
cd /mnt/gentoo
# set time
chronyd -q
# download the H/SELinux stage3 from here (ENSURE HTTPS!!!)
links https://www.gentoo.org/downloads/#amd64-advanced
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
```

- configure compile options
```bash
COMMON_FLAGS="-march=native -O2 -pipe"
FEATURES="${FEATURES} getbinpkg"
FEATURES="${FEATURES} binpkg-request-signature"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
MAKEOPTS="-j8"
VIDEO_CARDS="intel nouveau"
ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"
POLICY_TYPES="targeted"
# dist-kernel will allow kernel modules to automatically rebuild after kernel upgrade
USE="unicode X unconfined ubac peer_perms elogind pulseaudio alsa grub dist-kernel"
LC_MESSAGES=C.utf8
GRUB_PLATFORMS="efi-64"
EMERGE_DEFAULT_OPTS="--getbinpkg"
```

- chroot
```bash
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
arch-chroot /mnt/gentoo
source /etc/profile
export PS1="(chroot) ${PS1}"
```

- prepare for bootloader
```bash
mkdir /efi
mount /dev/sda1 /efi
```

- portage sync
```bash
emerge-webrsync
eselect news list
eselect news read
```

- choose profile
```bash
eselect profile set 43
eselect profile list
# default/linux/amd64/23.0/hardened/selinux (stable) *
```

- configure the binhost
```bash
### /etc/portage/binrepos.conf/gentoobinhost.conf
[binhost]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/<arch>/binpackages/<profile>/x86-64/


### run
getuto
```

- configure licensing
```bash
echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" | tee -a /etc/portage/package.license
echo "sys-firmware/intel-microcode intel-ucode" | tee -a /etc/portage/package.accept_keywords
echo "sys-firmware/intel-microcode ~amd64" | tee -a /etc/portage/package.accept_keywords
```

- update @world
```bash
emerge --ask --verbose --update --deep --newuse @world
emerge --ask --depclean
```

- configure timezones
```bash
echo "Europe/Germany" > /etc/timezone
emerge --config sys-libs/timezone-data
```

- configure locales
```bash
### /etc/locale.gen
en_US ISO-8859-1
en_US.UTF-8 UTF-8

### run the following
locale-gen
eselect locale set 2
# [2]  C.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

- install microcode and firmware
```bash
# microcode for AMD is also in this package:
emerge --ask sys-kernel/linux-firmware
emerge --ask sys-firmware/intel-microcode
emerge -av cryptsetup btrfs btrfs-progs
```

- configure installkernel with dracut
```bash
### /etc/portage/package.use/installkernel
sys-kernel/installkernel dracut grub
```

- installer-side configure dracut
  dracut will be run automatically by `emerge gentoo-kernel-bin` and generate an initramfs inside /boot
```bash
### /etc/dracut.conf
# minimum components to decrypt LUKS volumes using dracut
add_dracutmodules+=" crypt crypt-gpg dm rootfs-block btrfs "
# Embed cmdline parameters for rootfs decryption (obtain uuids with `lsblk -o name,uuid`)
kernel_cmdline+=" loglevel=6 rd.luks.key=/crypt_key.luks.gpg:UUID=0e86bef-30f8-4e3b-ae35-3fa2c6ae705b rootfstype=btrfs rd.luks.uuid=4bb45bd6-9ed9-44b3-b547-b411079f043b root=UUID=cb070f9e-da0e-4bc5-825c-b01bb2707704 "


### /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=6"
GRUB_DEVICE=UUID=cb070f9e-da0e-4bc5-825c-b01bb2707704
```

- install signed kernel
  if EFI binaries will be signed with a custom key for secure boot make.conf should be adjusted: [https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Optional:_Signed_kernel_modules](https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Optional:_Signed_kernel_modules)
```bash
emerge -av gentoo-sources
emerge -av dracut
emerge -av gentoo-kernel-bin
emerge -av installkernel
emerge --depclean

# The kernel modules in the sys-kernel/gentoo-kernel-bin are already signed
# The kernel image in the sys-kernel/gentoo-kernel-bin is already signed
```

- configure fstab
```bash
### lsblk -o name,uuid
NAME        UUID
sda
├──sda1     BDF2-0139
└──sda2     0e86bef-30f8-4e3b-ae35-3fa2c6ae705b
nvme0n1
└─nvme0n1p1 4bb45bd6-9ed9-44b3-b547-b411079f043b
  └─root    cb070f9e-da0e-4bc5-825c-b01bb2707704
```
```bash
# <fs>                                          <mountpoint>    <type>          <opts>          <dump/pass>
UUID=BDF2-0139                                  /efi            vfat            noauto,noatime  0 1
LABEL=boot                                      /boot           ext4            noauto,noatime  0 1
LABEL=rootfs                                    /               btrfs           defaults        0 1
```

- define hostname
```bash
echo tux > /etc/hostname
```

- setup dhcpcd
```bash
emerge --ask net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start
```

- setup hosts
```bash
192.168.1.69    dc-1.aisp.example.local
127.0.0.1       localhost
::1             localhost
```

- general system setup
```bash
passwd
emerge --ask net-misc/chrony
```

- defining bootloader
```bash
emerge -av sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg
```

- create swapfile
```bash
btrfs subvolume create swap_vol
chattr +C swap_vol
fallocate -l 4G swap_vol/swapfile
chmod 600 swap_vol/swapfile
mkswap swap_vol/swapfile
swapon swap_vol/swapfile

### /etc/fstab
/swap_vol/swapfile none swap sw 0 0
```

- SELinux-relabel the fs (opt)
```bash
mkdir /mnt/gentoo
mount -o bind / /mnt/gentoo
semodule -B
# initialize security contexts fileds on the fs
setfiles -r /mnt/gentoo /etc/selinux/targeted/contexts/files/file_contexts /mnt/gentoo/{dev,efi,proc,run,sys,tmp,etc,home}
umount /mnt/gentoo
semanage fcontext -a -t swapfile_t "/swap_vol/swapfile"
restorecon /swap_vol/swapfile
# relabel the entire fs
# (rlpkg is a gentoo specific tool that does the same thing as restorecon but for the entire fs)
rlpkg -a -r

### add kernel parameters in /etc/default/grub
GRUB_CMDLINE_LINUX=".....................  lsm=selinux"
grub-mkconfig
```

- SELinux user map
```bash
# map an existing administrative user to a domain other that unconfined_u
semanage login -a -s staff_u john
semanage login -a -s staff_u root
# -F is a key parameter here!!!
restorecon -RvF /home/john

semanage user -m -R "staff_r sysadm_r system_r" root
semanage user -m -R "staff_r sysadm_r system_r" staff_u
```

- /etc/sudoers
```bash
%wheel ALL=(ALL) TYPE=sysadm_t ROLE=sysadm_r ALL
```

- setup shim (secure boot) (optional)
            - the Secure Boot signature of vmlinuz is verified by firmware (UEFI), or sometimes by Shim (which overrides the firmware's SB verification). boot loaders usually call out to the firmware (or sometimes deliberately to Shim) to do the check.
            - the signatures of kernel modules are verified by the kernel itself, as the kernel is what handles its own module loading. there's no signature for the initramfs (if you use one), so there's no component that verifies it either, unless you combine it into vmlinuz in some way or other
            - kernel modules are signed using the certs/signing_key.pem file in kernel sources, this key is embedded into the kernel image upon build. modules are signed during modules_install phase of a kernel build.

```bash
# ensure secureboot USE is enabled globally

# generate keys
mkdir /certs && cd /certs
sudo openssl req -new -x509 -newkey rsa:2048 -subj "/CN=SecureBootSign/" -keyout sbs.key -out sbs.crt -days 3650 -nodes -sha256
# Convert to DER format
sudo openssl x509 -in sbs.crt -out sbs.cer -outform DER

### make.conf
# add the following in order for system to automatically sign all efi binaries with these keys
# this keypair should be in PEM format (BEGIN CERTIFICATE, BEGIN PRIVATE KEY)
USE="... secureboot modules-sign ..."
SECUREBOOT_SIGN_KEY="/certs/sbs.key"
SECUREBOOT_SIGN_CERT="/certs/sbs.crt"
MODULES_SIGN_KEY="/certs/sbs.key"
MODULES_SIGN_CERT="/certs/sbs.crt"


### !!! SHIM only checks signatures of the boot loader and kernel, but not the GRUB config file or initramfs
emerge sys-boot/shim sys-boot/mokutil
echo "sys-boot/grub **" | sudo tee -a /etc/portage/package.accept_keywords/main
emerge -avuU sys-boot/grub
### ALERT!!!! if you will do `cp /usr/lib/grub/grub-x86_64.efi.signed /efi/EFI/Gentoo/grubx64.efi` add grub config to EFI
### because this prebuild signed grub reads config from there instead of default /boot/grub/grub.cfg
# grub-mkconfig reads info from /etc/default/grub
echo "GRUB_CFG=/efi/EFI/Gentoo/grub.cfg" >> /etc/env.d/99grub


# add EFI entry for system to boot shim instead of GRUB
cp /usr/share/shim/BOOTX64.EFI /efi/EFI/Gentoo/shimx64.efi
cp /usr/share/shim/mmx64.efi /efi/EFI/Gentoo/mmx64.efi
cp /usr/lib/grub/grub-x86_64.efi.signed /efi/EFI/Gentoo/grubx64.efi
# grub-x86_64.efi.signed is automatically signed with SECUREBOOT_SIGN_CERT
sbverify --list /efi/EFI/gentoo/grubx64.efi

# add an EFI entry to point to shimx64.efi binary instead of grub
efibootmgr --disk /dev/sda --part 1 --create -L "GRUB via Shim" -l '\EFI\Gentoo\shimx64.efi'

# before running ensure /boot is mounted and kernels are there
grub-mkconfig -o /efi/EFI/gentoo/grub.cfg
# check that the config contains a menu entry for gentoo
grep "^menuentry" /efi/EFI/gentoo/grub.cfg

### NOT REQUIRED IF YOU USE gentoo-kernel-bin
# if you use gentoo-kernel-bin - it and it's modules automatically signed if USE="secureboot modules-sign" are enabled
# IF NOT - sign kernel and/or modules
sbsign --key ${SECUREBOOT_SIGN_KEY} --cert ${SECUREBOOT_SIGN_CERT} --output /boot/EFI/Gentoo/kernel-x.y.z-gentoo.efi /boot/EFI/Gentoo/kernel-x.y.z-gentoo.efi

### OPTIONAL: set EFI shell

# verify that the modules are signed by running hexdump against a random module
hexdump -C /usr/lib/modules/6.6.47-gentoo-dist/kernel/arch/x86/crypto/camellia-aesni-avx-x86_64.ko
# it should display "Module signature appended" at the end of a hexdump

### Add to MOK
# convert keys to DER for MOK
openssl x509 -inform pem -in ${SECUREBOOT_SIGN_CERT} -outform der -out /boot/sbcert.der
# import key into MOK (the password does NOT matter, it's a one time and required only during the first reboot)
sudo su -
mokutil --import /boot/sbcert.der
mokutil --ignore-keyring --import /usr/src/linux-6.6.47-gentoo-dist/certs/signing_key.x509
# qwerty123
reboot
# OPEN MOKManager => Enroll new key

# on next reboot you should enable validation
mokutil --sb-state # validate the secure boot and shim validation state, if not enabled:
mokutil --enable-validation
reboot
# OPEN UEFI => Security => Enable secure boot => SAVE and EXIT
# the MOKMANAGER should open
# OPEN MOKManager => change secure boot state => enter password you set earlier => Yes
```

- Make sure to lock UEFI with a strong passphrase and enable DMA protection!

