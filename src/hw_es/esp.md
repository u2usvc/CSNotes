# ESP
## ESP8266
### prepare env
[ESP8266 Core pkg](https://github.com/esp8266/arduino)
```bash
# confirm connected
arduino-cli board list

# update the core package index
arduino-cli core update-index

# initialize config
arduino-cli config init

# add additional board url (repo)
arduino-cli config add board_manager.additional_urls https://arduino.esp8266.com/stable/package_esp8266com_index.json

# update core index
arduino-cli core update-index

# search repos to confirm the newly installed repo is in the list
arduino-cli core search

# install package
arduino-cli core install esp8266:esp8266

# confirm installation
arduino-cli core list
```

## esptool
```bash
# display info about the chip, including the flash size
esptool.py --chip esp8266 --port /dev/ttyUSB0 flash_id
# Manufacturer: 68
# Device: 4016
# Detected flash size: 4MB

# dump flash memory from 0 to 4MB to a file called full_flash.bin
esptool.py --chip esp8266 --port /dev/ttyUSB0 read_flash 0x00000 0x400000 full_flash.bin
```
