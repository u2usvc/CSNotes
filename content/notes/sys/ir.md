# IR

## Windows

### Evtx

#### EvtxECmd

```bash
C:\Users\user\Desktop\Utilities\EvtxECmd\EvtxeCmd\EvtxECmd.exe -d 'C:\Users\user\Desktop\C___NONAME [NTFS]\Windows\System32\winevt\Logs' --csv C:\Users\user\desktop\evidence --csvf "C:\Users\user\Desktop\evidence\evtxecmd_output.csv"
```

### MFT

#### MFTECmd

```bash
.\MFTECmd.exe -f 'C:\Users\user\Desktop\C___NONAME [NTFS]\$MFT' --csv C:\Users\alex\desktop\evidence\ --csvf mftecmd_out.csv
```

### pf

#### PECmd

```bash
C:\Users\user\Desktop\Utilities\PECmd\PECmd.exe -d 'C:\Users\user\Desktop\C___NONAME [NTFS]\Windows\Prefetch' --csv C:\Users\user\desktop\evidence --csvf "C:\Users\user\Desktop\evidence\pecmd_output.csv"
```
