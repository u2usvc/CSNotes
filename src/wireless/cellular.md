# Cellular

## LTE sniffing

### LTESniffer Setup in docker

<https://github.com/SysSec-KAIST/LTESniffer>

1. Compile:

```Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    libfftw3-dev \
    libmbedtls-dev \
    libboost-all-dev \
    libconfig++-dev \
    libsctp-dev \
    libglib2.0-dev \
    libudev-dev \
    libcurl4-gnutls-dev \
    qtdeclarative5-dev \
    libqt5charts5-dev \
    python3-dev \
    python3-mako \
    python3-numpy \
    python3-requests \
    python3-setuptools \
    python3-ruamel.yaml \
    libhackrf-dev \
    libsoapysdr-dev \
    soapysdr-module-hackrf \
    soapysdr-tools \
    hackrf \
    automake \
    libncurses5-dev \
    libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root
RUN git clone https://github.com/EttusResearch/uhd.git && \
    cd uhd && \
    # Checkout a stable 4.x release
    git checkout v4.6.0.0 && \
    cd host && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

WORKDIR /root
RUN git clone https://github.com/SysSec-KAIST/LTESniffer.git && \
    cd LTESniffer && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j$(nproc)

WORKDIR /root/LTESniffer/build/src
CMD ["/bin/bash"]
```

```bash
docker build -t ltesniffer-hackrf .
```

2. Pass the device to a container (determine IDs from `lsusb`, e.g. `Bus 001 Device 060: HackRF`)

```bash
docker run -it --rm \
  --device=/dev/bus/usb/001/060 \
  -v ~/test/ltesniffer/data:/data \
  ltesniffer-hackrf
```

3. Ensure device is recognized

```bash
SoapySDRUtil --probe="driver=hackrf"
```

4. Determine downlink frequency e.g. via Cellular-Z. (cellular-z displays it as `FREQ downlink/uplink`)

5. Launch

```bash
# -A Number of RX antennas [Default 1]
# -W Number of concurent threads [2..W, Default 4]
# -C Enable cell search, default disable
# -m Sniffer mode, 0 for downlink sniffing mode, 1 for uplink sniffing mode
# -g RF fix RX gain [Default AGC]
# -f Downlink Frequency
# -a RF args [Default ]

# considering the downlink frequency determined is 1845.2 MHz
./LTESniffer -f 1845.2e6 -m 0 -g 60 -a "driver=hackrf"
```
