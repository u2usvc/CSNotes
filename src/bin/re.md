# RE

## Utils

### windbg

#### Usage

[https://github.com/f1zm0/WinDBG-Cheatsheet](https://github.com/f1zm0/WinDBG-Cheatsheet)

```bash
# print memory state at the address specified in ESP pointer
db esp
# print 200 bytes
db esp L200

# dissasemble the function `GetCurrentThread` in `kernel32` DLL
u kernel32!GetCurrentThread
```

#### display security descriptor at address

```bash
!sd $ADDRESS
```
Ace0 will contain the S-1-0-0 SID (all users). Use the following script to decode this mask: [https://raw.githubusercontent.com/Xacone/Eneio64-Driver-Exploits/refs/heads/main/sd.py](https://raw.githubusercontent.com/Xacone/Eneio64-Driver-Exploits/refs/heads/main/sd.py)
```
0x00010000: "DELETE",
0x00020000: "READ_CONTROL",
0x00040000: "WRITE_DAC",
0x00080000: "WRITE_OWNER",
0x00100000: "SYNCHRONIZE",
0x00000001: "FILE_READ_DATA",
0x00000002: "FILE_WRITE_DATA",
0x00000004: "FILE_APPEND_DATA",
0x00000008: "FILE_READ_EA",
0x00000010: "FILE_WRITE_EA",
0x00000020: "FILE_EXECUTE",
0x00000040: "FILE_DELETE_CHILD",
0x00000080: "FILE_READ_ATTRIBUTES",
0x00000100: "FILE_WRITE_ATTRIBUTES",
0x00020000: "STANDARD_RIGHTS_READ",
0x00020000: "STANDARD_RIGHTS_WRITE",
0x00020000: "STANDARD_RIGHTS_EXECUTE",
0x001f0000: "STANDARD_RIGHTS_ALL",
0x10000000: "GENERIC_ALL",
0x20000000: "GENERIC_EXECUTE",
0x40000000: "GENERIC_WRITE",
0x80000000: "GENERIC_READ",
```

#### display structure property under specified address

[DEVICE_OBJECT structure](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_device_object)

```cpp
typedef struct _DEVICE_OBJECT {
  PSECURITY_DESCRIPTOR SecurityDescriptor;
}
```

```bash
# return structure definition
dt $STRUCT
dt _DEVICE_OBJECT

# return specific structure
dt $STRUCT $ADDRESS
dt _DEVICE_OBJECT ffffe2010f21b780

# return specific attribute within the specific structure
dt $STRUCT $ADDRESS $ATTRIBUTE
dt _DEVICE_OBJECT ffffe2010f21b780 SecurityDescriptor
```

#### search base address of a function by it's symbol

```bash
# ensure symbols
.symfix
# reload ntdll.dll with symbols
.reload /f ntdll.dll

# display base address of an NtTraceEvent function within ntdll.dll by it's symbol
x ntdll!NtTraceEvent

# dissasemble the function
uf ntdll!NtTraceEvent
```

#### windows driver debugging setup

```bash
# change boot configuration to include /debug option (???)
# BitLocker and secureboot need to be disabled first
bcdedit -debug on
```
1. Launch windbg
2. File -> Attach to kernel -> Local -> OK
