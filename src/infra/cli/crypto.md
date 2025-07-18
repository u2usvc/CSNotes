# Crypto
## gpg
```bash
# generate the key
gpg --full-gen-key

# Signature verification example
gpg --keyserver-options auto-key-retrieve --verify Downloads/archlinux-2023.09.01-x86_64.iso.sig Documents/archlinux-2023.09.01-x86_64.iso

# pass
gpg --full-gen-key
gpg --list-keys
gpg --edit-key user-id                # Edit key

### MESSAGE EXCHANGE
# export public key from a keyring to a file
gpg --output $FILE --export $KEY_UID            # add --armor to export in ASCII
# sign a file with a public key 
gpg --output $OUT_FILE --encrypt --recipient $KEY_UID $FILE
```


## pass
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

