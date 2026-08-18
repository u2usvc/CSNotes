# Crypto

## CLI

### LUKS

#### create LUKS directory-in-file

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

### gpg

#### keys

```bash
gpg --full-gen-key
gpg --list-keys
gpg --edit-key user-id
```

#### message exchange

```bash
# export public key from a keyring to a file
gpg --output $FILE --export $KEY_UID            # add --armor to export in ASCII
# sign a file with a public key 
gpg --output $OUT_FILE --encrypt --recipient $KEY_UID $FILE
```

#### signature verification

Retrieves public key address from .sig file and fetches it from the remote server

```bash
gpg --keyserver-options auto-key-retrieve --verify Downloads/archlinux-2023.09.01-x86_64.iso.sig Documents/archlinux-2023.09.01-x86_64.iso
```

### openssl

#### generate certificate with SAN for Proxmox

```bash
openssl req -new -newkey rsa:2048 -nodes -keyout pve.key -out pve.csr -subj "/OU=PVE Cluster Node/O=Proxmox Virtual Environment/CN=pve.aperture.ad" -addext "subjectAltName=DNS:pve.aperture.ad,DNS:127.0.0.1,DNS:localhost,DNS:pve,DNS:192.168.88.69" && openssl x509 -req -in pve.csr -CA k8s-aperture-root-ca-01.crt -CAkey k8s-aperture-root-ca-01.key -CAcreateserial -out pve.crt -days 365 -sha256 -extfile <(printf "subjectAltName=DNS:pve.aperture.ad,DNS:127.0.0.1,DNS:localhost,DNS:pve,DNS:192.168.88.69")

```

### pass

#### usage

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

## Hashcracking

### hashcat

```bash
### OPTIONS
--help              # display hash types
-m [hash_type]      # specify hash type
-a [mode]           # specify attack-mode (???)
-O                  # enable optimized kernel mode

--increment         # increment applied mask by 1


################
### EXAMPLES ###
################
hashcat -O -a 0 -m 3200 hash.txt ~/SecLists/rockyou.txt
hashcat 'iamthehash'                                           # determine hash type
hashcat -O -a 0 -m 1800 '$6$uWBSeTcoXXTBRkiL$S9ipksJfiZuO4bFI6I9w/iItu5.Ohoz3dABeF6QWumGBspUW378P1tlwak7NqzouoRTbrz6Ag0qcyGQxW192y/' ~/SecLists/rockyou.txt

# Cracked password is supplied in the following format:
$2y$10$IT4k5kmSGvHSO9d6M/1w0eYiB5Ne9XzArQRFJTGThNiy/yBtkIj12:tequieromucho


### Hashcat show examples for pbkdf2 + sha256
hashcat --example-hashes --mach | grep -i pbkdf2 | grep sha256


### MASKS
# https://hashcat.net/wiki/doku.php?id=mask_attack
hashcat -m 1400 -O -a 3 --increment 'abeb6f8eb5722b8ca3b45f6f72a' 'susan_nasus_?d?d?d?d?d?d?d?d?d?d'

hashcat -m 1400 -O -a 6 "somehash" example.dict ?d?d?d?d
# password0000
# password0001

hashcat -m 1400 -O -a 7 "somehash" ?d?d?d?d example.dict
# 0000password
# 0001password

hashcat -m 1400 -O -a 7 "somehash" dict1.txt dict2.txt
```

### john

```bash
# john works with files, store hash into a file first
echo 'dsgf27g86df26f287df86f3' | tee -a hash.txt

# determine possible formats
john --show=formats hash.txt

# crack using a specific format
john --format=Raw-MD5 --wordlist=/usr/share/wordlists/rockyou.txt hash.txt

# crack using all formats
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```
