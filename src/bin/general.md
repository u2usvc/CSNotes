# General

## pwntools

- [cryptocat's binexp-101](https://github.com/Crypto-Cat/CTF/tree/main/pwn/binary_exploitation_101)

```python
# import lib
from pwn import *

# setup the proc
p = process('./vuln-32')

# clear logs
log.info(p.clean())
# send the line
p.sendline('%23$p')

canary = int(p.recvline(), 16)
log.success(f'Canary: {hex(canary)}')
```

```bash
### asm (compile shellcode)

# compile into elf

pwn asm -i exploit_unc.asm -f elf -o exploit_unc.elf

# compile into string for injection

pwn asm -i exploit_unc.asm -f string
```

payload craft example:

```bash
python2 -c 'print "aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaab" + "EIPx" + "nausdifu" + "\x50\xbb\x01\x00\x00\x00\x89\xe1\xba\x1e\x00\x00\x00\xb8\x04\x00\x00\x00\xcd\x80\xb8\x01\x00\x00\x00\xcd\x80"' > payload.bin
```

## windbg

```bash
# show registers
r
# show register state
r eax,esp

# print memory state at the address specified in ESP pointer
db esp
# print 200 bytes
db esp L200


# set breakpoint
bp kernel32!GetCurrentThread
# remove breakpoints
bc *

# dissasemble the function `GetCurrentThread` in `kernel32` DLL
u kernel32!GetCurrentThread
```

## gdb-pwndbg

```bash
gdb-pwndbg ./file


# place a breakpoint at main
break main

# continue program execution
continue

# list functions
info functions

# run the program
run
run < payload.bin

# print first 20 entries in stack
stack 29

# step into
si
# step over
so


# generate cyclic 200 symbols
cyclic 200
# find offset of "waab"
cyclic -l waab


# breaks when EIP will be equal to 0xffff0d98 (insert while running)
watch $eip == 0xffff0d98



# display virtual memory map
vmmap
```

## r2

```bash
### CLI
# open
r2 ./vuln
# debug
r2 -d ./vuln
# writable open
r2 -w ./vuln

### Basic stuff
# analyse everything
aaaa
# display function list
afl
# display calling convention
afc
# seek to function (you can do the same with addresses)
s sym.flag
# go to visual mode (press again to go into graph mode)
V
# print dissasembled funciton
pdf
# print 20 dissasembled instructions from current address
pd 20
```
