# RF

## HackRF

### Replay

```bash
# capture on 315'000.000kHz (315.000 MHz) and save to a file called "unlock.rx" and sample rate of 2'000.000 kHz (2 MHz)
sudo hackrf_transfer -s 2000000 -f 315000000 -r unlock.rx

# transmit file contents with 47 db (maximum) gain
sudo hackrf_transfer -s 2000000 -f 315000000 -t unlock.rx -x 47
```

### flash

grab from here - [https://github.com/mossmann/hackrf](https://github.com/mossmann/hackrf)

```bash
# just run the following command and reconnect the board
sudo hackrf_spiflash -w hackrf_one_usb.bin

# run to ensure firmware got flashed
sudo hackrf_info
```
