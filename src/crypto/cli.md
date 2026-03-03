# CLI

## LUKS

### create LUKS directory-in-file

<https://www.lpenz.org/articles/luksfile/>

```bash
dd if=/dev/zero of=cryptfile.img bs=1M count=64
sudo cryptsetup luksFormat cryptfile.img
sudo cryptsetup luksOpen cryptfile.img cryptdev
sudo mkfs.ext4 /dev/mapper/cryptdev
sudo cryptsetup luksClose cryptdev

# mount
sudo cryptsetup luksOpen cryptfile.img cryptdev
sudo mount -t auto /dev/mapper/cryptdev ./cryptdir

# umount
sudo umount cryptdir
sudo cryptsetup luksClose cryptdev
```

## gpg

### keys

```bash
gpg --full-gen-key
gpg --list-keys
gpg --edit-key user-id
```

### message exchange

```bash
# export public key from a keyring to a file
gpg --output $FILE --export $KEY_UID            # add --armor to export in ASCII
# sign a file with a public key 
gpg --output $OUT_FILE --encrypt --recipient $KEY_UID $FILE
```

### signature verification

Retrieves public key address from .sig file and fetches it from the remote server

```bash
gpg --keyserver-options auto-key-retrieve --verify Downloads/archlinux-2023.09.01-x86_64.iso.sig Documents/archlinux-2023.09.01-x86_64.iso
```

## pass

### usage

```bash
gpg --full-gen-key
pass init $GPG_ID                   # will reencrypt

# Usage
pass ls                             # list passwords
pass insert dir/file                # Insert password
pass -c dir/file                    # Copy password to clipboard
pass edit dir/file                  # Insert other fields
pass generate dir/file $NUM         # Generate password

# change pass dir (should have .gpg-id file)
PASSWORD_STORE_DIR=/mnt/sda1/my/password/storage
```
