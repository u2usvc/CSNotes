# Syscalls

## SSN sorting

### TartarusGate, HellsGate, HalosGate

- <https://github.com/reveng007/DarkWidow/blob/main/src%2FSyscallStuff.h>

```cpp
#define UP -32
#define DOWN 32

#include <windows.h>

WORD GetSyscallNum(LPVOID ntapiaddr)
{
  WORD SystemCall = NULL;

  if (*((PBYTE)ntapiaddr) == 0x4c
    && *((PBYTE)ntapiaddr + 1) == 0x8b
    && *((PBYTE)ntapiaddr + 2) == 0xd1
    && *((PBYTE)ntapiaddr + 3) == 0xb8
    && *((PBYTE)ntapiaddr + 6) == 0x00
    && *((PBYTE)ntapiaddr + 7) == 0x00)
  {
    BYTE high = *((PBYTE)ntapiaddr + 5);
    BYTE low = *((PBYTE)ntapiaddr + 4);
    SystemCall = (high << 8) | low;
    return SystemCall;
  }

  if (*((PBYTE)ntapiaddr) == 0xe9 || *((PBYTE)ntapiaddr + 3) == 0xe9 || *((PBYTE)ntapiaddr + 8) == 0xe9 ||
    *((PBYTE)ntapiaddr + 10) == 0xe9 || *((PBYTE)ntapiaddr + 12) == 0xe9)
  {
    for (WORD idx = 1; idx <= 500; idx++)
    {
      if (*((PBYTE)ntapiaddr + idx * DOWN) == 0x4c
        && *((PBYTE)ntapiaddr + 1 + idx * DOWN) == 0x8b
        && *((PBYTE)ntapiaddr + 2 + idx * DOWN) == 0xd1
        && *((PBYTE)ntapiaddr + 3 + idx * DOWN) == 0xb8
        && *((PBYTE)ntapiaddr + 6 + idx * DOWN) == 0x00
        && *((PBYTE)ntapiaddr + 7 + idx * DOWN) == 0x00)
      {
        BYTE high = *((PBYTE)ntapiaddr + 5 + idx * DOWN);
        BYTE low = *((PBYTE)ntapiaddr + 4 + idx * DOWN);
        SystemCall = (high << 8) | low - idx;
        return SystemCall;
      }

      if (*((PBYTE)ntapiaddr + idx * UP) == 0x4c
        && *((PBYTE)ntapiaddr + 1 + idx * UP) == 0x8b
        && *((PBYTE)ntapiaddr + 2 + idx * UP) == 0xd1
        && *((PBYTE)ntapiaddr + 3 + idx * UP) == 0xb8
        && *((PBYTE)ntapiaddr + 6 + idx * UP) == 0x00
        && *((PBYTE)ntapiaddr + 7 + idx * UP) == 0x00)
      {
        BYTE high = *((PBYTE)ntapiaddr + 5 + idx * UP);
        BYTE low = *((PBYTE)ntapiaddr + 4 + idx * UP);
        SystemCall = (high << 8) | low + idx;
        return SystemCall;
      }
    }
  }
}
```

```cpp
DWORD64 GetSyscallAddr(LPVOID ntapiaddr)
{
  WORD SystemCall = NULL;

  if (*((PBYTE)ntapiaddr) == 0x4c
    && *((PBYTE)ntapiaddr + 1) == 0x8b
    && *((PBYTE)ntapiaddr + 2) == 0xd1
    && *((PBYTE)ntapiaddr + 3) == 0xb8
    && *((PBYTE)ntapiaddr + 6) == 0x00
    && *((PBYTE)ntapiaddr + 7) == 0x00)
  {
    INT_PTR addr = (INT_PTR)ntapiaddr + 0x12;
    return addr;
  }

  if (*((PBYTE)ntapiaddr) == 0xe9 || *((PBYTE)ntapiaddr + 3) == 0xe9 || *((PBYTE)ntapiaddr + 8) == 0xe9 ||
    *((PBYTE)ntapiaddr + 10) == 0xe9 || *((PBYTE)ntapiaddr + 12) == 0xe9)
  {
    for (WORD idx = 1; idx <= 500; idx++)
    {
      if (*((PBYTE)ntapiaddr + idx * DOWN) == 0x4c
        && *((PBYTE)ntapiaddr + 1 + idx * DOWN) == 0x8b
        && *((PBYTE)ntapiaddr + 2 + idx * DOWN) == 0xd1
        && *((PBYTE)ntapiaddr + 3 + idx * DOWN) == 0xb8
        && *((PBYTE)ntapiaddr + 6 + idx * DOWN) == 0x00
        && *((PBYTE)ntapiaddr + 7 + idx * DOWN) == 0x00)
      {
        INT_PTR addr = (INT_PTR)ntapiaddr + 0x12;
        return addr;
      }

      if (*((PBYTE)ntapiaddr + idx * UP) == 0x4c
        && *((PBYTE)ntapiaddr + 1 + idx * UP) == 0x8b
        && *((PBYTE)ntapiaddr + 2 + idx * UP) == 0xd1
        && *((PBYTE)ntapiaddr + 3 + idx * UP) == 0xb8
        && *((PBYTE)ntapiaddr + 6 + idx * UP) == 0x00
        && *((PBYTE)ntapiaddr + 7 + idx * UP) == 0x00)
      {
        INT_PTR addr = (INT_PTR)ntapiaddr + 0x12;
        return addr;
      }
    }
  }
}
```

## calls

### Indirect

see SSN sorting techniques for `GetSyscallNum` and `GetSyscallAddr`

```cpp
template<typename Fn, typename... Args>
auto call(DWORD64 dllHash, DWORD64 apiHash, Fn func, Args... args) -> decltype(func(args...)) {
  HMODULE dllBase = resolve_lib(dllHash);
  LPVOID pApi = resolve_api(dllBase, apiHash);

  WORD syscallNum = GetSyscallNum(pApi);
  DWORD64 syscallAddr = GetSyscallAddr(pApi);

  PrepSyscallNum(syscallNum);
  PrepSyscallAddr(syscallAddr);

  return func(args...);
}
```

- <https://github.com/SaadAhla/D1rkLdr/blob/main/D1rkLdr/D1rk%20Loader/syscalls.asm>
- <https://github.com/CognisysGroup/HadesLdr/blob/main/IDSyscall/IDSyscall/syscallStuff.asm>

```asm
BITS 64
default rel

section .data
    SSN         dw 0
    syscallAddr dq 0

section .text
global PrepSyscallNum
PrepSyscallNum:
    mov word [SSN], cx
    ret

global PrepSyscallAddr
PrepSyscallAddr:
    mov qword [syscallAddr], rcx
    ret

global sysNtOpenProcessToken
sysNtOpenProcessToken:
    mov r10, rcx
    mov ax, word [SSN]
    jmp qword [rel syscallAddr]
    ret
```
