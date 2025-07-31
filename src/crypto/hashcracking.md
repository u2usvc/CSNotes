# hashcracking

## hashcat

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

## john

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
