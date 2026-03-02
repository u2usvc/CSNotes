# BinExp

## Utils

### gdb-pwndbg

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
