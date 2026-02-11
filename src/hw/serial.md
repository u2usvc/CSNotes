# Serial

## UART

### FTDI FT232H

[DOC: breakout pinout](https://learn.adafruit.com/adafruit-ft232h-breakout/serial-uart)

```bash
sudo su
python3 -m venv ./
. ./bin/activate

# <https://eblot.github.io/pyftdi/installation.html>
pip install pyftdi

# determine URL
sudo ./bin/ftdi_urls.py
```

pyftdi provides a ready-to-use utility for UART communication

```bash
python3 bin/pyterm.py ftdi://ftdi:232h:1:46/1
```

### Generic

- TX - RX
- RX - TX
- GND - GND

```bash
ls -ltr /dev/*USB*

sudo picocom -b 115200 /dev/ttyUSB0
```
