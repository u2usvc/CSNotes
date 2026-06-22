# Obfuscation

## Codecepticon

### Usage

```bash
# install prerequisites  (.NET VSC, Roslyn)
git clone https://github.com/sadreck/Codecepticon.git
cd Codecepticon/Codecepticon
dotnet build

### --path should be a path to an sln !!!
### thus, generate an sln and add your project as a reference to that sln :
# VSCommunity => File => New => Project => Empty Solution
# VSCommunity => File => Add => Existing Project
# VSCommunity => Build => Publish Selection                       # needed in order for reference to appear in .sln

# obfuscate
cd Codecepticon/Codecepticon/bin/Debug/net472/
.\Codecepticon.exe --action obfuscate --module csharp --verbose --path "C:\Users\Administrator\Downloads\repos\Solution1\Solution1.sln" --rename ncefpavs --rename-method markov --markov-min-length 3 --markov-max-length 9 --markov-min-words 3 --markov-max-words 4
```

## Hashing

### API hashing

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

## OLLVM

### Build

```Dockerfile
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN git clone -b llvm-4.0 https://github.com/obfuscator-llvm/obfuscator.git

WORKDIR /usr/src/build

RUN cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF ../obfuscator/

RUN make -j$(nproc)

RUN ./bin/clang --version

CMD ["/bin/bash"]
```

```bash
sudo docker build -t obfuscator-llvm .
sudo docker cp $CONTAINER_ID:/usr/src/build/bin ~/utils/ollvm/
sudo docker cp $CONTAINER_ID:/usr/src/build/lib ~/utils/ollvm/
sudo docker cp $CONTAINER_ID:/usr/src/build/include ~/utils/ollvm/
```

## PIC

### SGN

#### Usage

```bash
docker pull egee/sgn
ls ~/utils/shellcode.bin
docker run -it -v ~/utils:/data egee/sgn -a 64 /data/shellcode.bin
ls ~/utils/shellcode.bin.sgn
```

## garble

### Usage

```bash
go install mvdan.cc/garble@latest

# `go build ...` ->
garble -literals -tiny build ...
```
