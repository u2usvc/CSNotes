# Resolution

## API

### DInvoke

```csharp
address = DInvoke.GetLibraryAddress("ntdll.dll",
    Constants.Methods.NtOpenProcess, hashKey);
Interop.NtOpenProcess ntOpenProcess =
  Marshal.GetDelegateForFunctionPointer(address, typeof(Interop.NtOpenProcess)) as Interop.NtOpenProcess;
Interop.NtStatus status = ntOpenProcess(ref hProcess,
    Interop.PROCESS_ACCESS_RIGHTS.PROCESS_ALL_ACCESS,
    ref ObjectAttributes, ref clientid);
```

### WINAPI hashing

```cpp
void* resolve_api(void* dllBase, uint64_t apiHash) {
  IMAGE_DOS_HEADER* DOS_HEADER = (IMAGE_DOS_HEADER*)dllBase;
  IMAGE_NT_HEADERS* NT_HEADER = (IMAGE_NT_HEADERS*)((LPBYTE)dllBase + DOS_HEADER->e_lfanew);
  PIMAGE_EXPORT_DIRECTORY EXdir = (PIMAGE_EXPORT_DIRECTORY)((LPBYTE)dllBase + NT_HEADER->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);

  PDWORD fAddr = (PDWORD)((LPBYTE)dllBase + EXdir->AddressOfFunctions);
  PDWORD fNames = (PDWORD)((LPBYTE)dllBase + EXdir->AddressOfNames);
  PWORD  fOrdinals = (PWORD)((LPBYTE)dllBase + EXdir->AddressOfNameOrdinals);

  for (DWORD i = 0; i < EXdir->AddressOfFunctions; i++)
  {
    LPSTR pFuncName = (LPSTR)((LPBYTE)dllBase + fNames[i]);
    DWORD64 calculatedHash = hash(pFuncName);

    if (calculatedHash == apiHash)
    {
      LPVOID baseFuncAddr = (LPVOID)((LPBYTE)dllBase + fAddr[fOrdinals[i]]);
      return baseFuncAddr;
    }
  }
  return 0;
}
```

## PID

### NtGetNextProcess

#### Execution

```cpp
EXTERN_C NTSTATUS sysNtGetNextProcess(
  HANDLE ProcessHandle,
  ACCESS_MASK DesiredAccess,
  ULONG HandleAttributes,
  ULONG Flags,
  PHANDLE NewProcessHandle
);

DWORD findProcessId(std::string processName) {
  DWORD pid = 0;
  HANDLE hProcess = NULL;
  char procName[MAX_PATH];

  while (NT_SUCCESS(call(
    hashNtDll,
    hashNtGetNextProcess,
    sysNtGetNextProcess,
    hProcess,
    MAXIMUM_ALLOWED,
    0,
    0,
    &hProcess
  ))) {
    memset(procName, 0, MAX_PATH);

    DWORD nameLength = GetProcessImageFileNameA(hProcess, procName, MAX_PATH);
    if (nameLength == 0) continue;

    LPCSTR fileName = PathFindFileNameA(procName);

    if (lstrcmpiA(fileName, processName.c_str()) == 0) {
      pid = GetProcessId(hProcess);
      break;
    }
  }

  return pid;
}
```

#### Resources

- <https://cocomelonc.github.io/malware/2023/05/26/malware-tricks-30.html>

### find PID via `\proc\$PID\comm`

```cpp
pid_t findProcessId(std::string processName) {
  DIR* proc = opendir("/proc");
  if (proc == nullptr) return 0;

  pid_t found = 0;
  struct dirent* entry;
  while ((entry = readdir(proc)) != nullptr) {
    if (entry->d_name[0] < '0' || entry->d_name[0] > '9') continue;

    char commPath[64];
    snprintf(commPath, sizeof(commPath), "/proc/%s/comm", entry->d_name);

    // cat /proc/self/comm == "cat"
    FILE* f = fopen(commPath, "r");
    if (f == nullptr) continue;

    char comm[256] = {0};
    // read `f` and store the result into `comm`
    if (fgets(comm, sizeof(comm), f) != nullptr) {
      size_t len = strlen(comm);
      if (len > 0 && comm[len - 1] == '\n') comm[len - 1] = '\0';

      if (processName == comm) {
        found = (pid_t)atoi(entry->d_name);
        fclose(f);
        break;
      }
    }
    fclose(f);
  }

  closedir(proc);
  return found;
}
```

## Shared lib

### DLL hashing

```cpp
void* resolve_lib(uint64_t dllHash) {
  PNT_TIB pTIB = NULL;
  PTEB pTEB = NULL;
  PPEB pPEB = NULL;

  pTIB = (PNT_TIB)__readgsqword(0x30);
  pTEB = (PTEB)pTIB->Self;
  pPEB = (PPEB)pTEB->ProcessEnvironmentBlock;

  if (pPEB == NULL) {
    return NULL;
  }

  PPEB_LDR_DATA pPEB_LDR_DATA = (PPEB_LDR_DATA)(pPEB->Ldr);
  PLIST_ENTRY ListHead, ListEntry;
  PLDR_DATA_TABLE_ENTRY LdrEntry;

  ListHead = &pPEB->Ldr->InLoadOrderModuleList;
  ListEntry = ListHead->Flink;

  while (ListHead != ListEntry) {
    LdrEntry = CONTAINING_RECORD(ListEntry, LDR_DATA_TABLE_ENTRY, InLoadOrderLinks);

    UNICODE_STRING BaseDllName = (LdrEntry->FullDllName);
    HMODULE DllBase = (HMODULE)(LdrEntry->DllBase);

    const char *Dllname = PWSTR_to_Char(BaseDllName.Buffer);
    DWORD64 retrievedhash = hash(Dllname);

    if (retrievedhash == dllHash) {
      return DllBase;
    }

    ListEntry = ListEntry->Flink;
  }
  return 0;
}
```

### resolve SO address from link_map

```cpp
#include <cstdint>
#include <cstdio>
#include <elf.h>
#include <link.h>
#include "../hash/hash.hpp"
#include "../static/debug.hpp"

void* resolve_lib(uint64_t libHash) {
  // resolve the address of .dynamic section
  extern Elf64_Dyn _DYNAMIC[];

  r_debug* dbg = nullptr;
  for (Elf64_Dyn* dyn = _DYNAMIC; dyn->d_tag != DT_NULL; dyn++) {
    if (dyn->d_tag == DT_DEBUG) {
      dbg = (r_debug*)dyn->d_un.d_ptr;
    }
  }
  if (dbg == nullptr) {
    DEBUG_ERR("Failed to get r_debug");
    return nullptr;
  }
  DEBUG_TRACE("Found r_debug: %p", dbg);

  for (link_map* lm = dbg->r_map; lm != nullptr; lm = lm->l_next) {
    uint64_t retrievedhash = hash(lm->l_name);
    DEBUG_TRACE("Retrieved hash: %lu", retrievedhash);
    DEBUG_TRACE("SO hash: %lu", libHash);

    if (retrievedhash == libHash) {
      DEBUG_VERBOSE("lib resolved");
      return lm;
    }
  }

  return nullptr;
}
```
