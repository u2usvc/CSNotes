# Flash dump

## Native

### esptool

```bash
# display info about the chip (including the flash size which is important)
sptool.py --chip esp8266 --port /dev/ttyUSB0 flash_id
# Manufacturer: 68
# Device: 4016
# Detected flash size: 4MB

# dump flash memory to a file called full_flash.bin (0x400000 == 4MB)
sptool.py --chip esp8266 --port /dev/ttyUSB0 read_flash 0x00000 0x400000 full_flash.bin
```
