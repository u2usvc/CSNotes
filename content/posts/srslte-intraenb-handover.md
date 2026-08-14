---
title: "srsLTE intra-eNB handover on ZMQ"
date: 2026-03-28
description: "Setting up intra-eNB handover lab on srsLTE with ZMQ"
tags: ["wireless"]
---

## Architecture

One eNB manages two cells. ZMQ exposes separate TCP ports per cell. GRC broker controls per-cell gain via sliders to trigger handover.

| Direction | Cell 1 | Cell 2 | UE   |
|-----------|--------|--------|------|
| RX        | 2100   | 2200   | 2000 |
| TX        | 2101   | 2201   | 2001 |

- Each TX is a separate GRC source. Each RX is a separate GRC sink.
- UE TX (`localhost:2001`) gets splited into 2 and each goes to GRC sinks that correspond to cell1 and cell2 ports (`tcp://*:2100` and `tcp://*:2200`)
- Cells TX get added together and go to GRC sink that correspond to UE RX port (`tcp://*:2000`)

- The `ue.conf` file defines the following `device_args = fail_on_disconnect=true,id=enb,tx_port0=tcp://*:2101,tx_port1=tcp://*:2201,rx_port0=tcp://localhost:2100,rx_port1=tcp://localhost:2200,id=enb,base_srate=23.04e6`
- The `rr.conf` file assigns cells to the eNB

## Configuration

Files shared earlier already provide necessary configuration. Here's the summary:

- TAC (tracking area code) of the cells must match that of the MME
- EARFCN (frequency identifier) must be the same across both cells and the UE
- PCI (physical cell identifier) of each cell with the same EARFCN must be different
- ZMQ must be name the default device for both the eNB and UE

## Setup

- Handover w/ ZMQ (contains all required information for the setup, you don't need to read the zeromq app note): <https://docs.srsran.com/projects/4g/en/next/app_notes/source/handover/source/index.html>
- srsLTE Intra eNB Handover w/ GNU Radio (srsLTE, ZMQ): <https://youtu.be/7ut_EvhINMc>, <https://youtu.be/airALZwx0xE>
- see known issues: <https://docs.srsran.com/projects/4g/en/next/app_notes/source/zeromq/source/index.html#known-issues>

"Intra-eNB Handover describes the handover between cells when a UE moves from one sector to another sector. **These handovers are managed by the same eNB**. The following steps show how ZMQ and GRC can be used with srsRAN 4G to demonstrate such a handover."

Requires srsRAN 4G release 20.10 or later (with ZMQ support compiled-in). Display version and commit:

```bash
srsepc --version | grep 'using commit'
# https://github.com/srsran/srsRAN_4G/commit/$COMMIT
```

UE and EPC must run in separate network namespaces to prevent the Linux kernel from bypassing TUN interfaces. Create namespace:

```bash
sudo ip netns add ue1
sudo ip netns list
```

Ensure `ue.conf`, `enb.conf`, `rr.conf` files are present and required `.grc` (GNU Radio Companion) file is obtained. These files can be downloaded here: <https://docs.srsran.com/projects/4g/en/next/app_notes/source/handover/source/index.html>
The architecture is as follows: `srsUE --- GRC Broker --- srsENB(cell1, cell2) --- srsEPC`

Run

```bash
sudo srsepc

sudo srsenb --enb_files.rr_config ~/Downloads/rr.conf ~/Downloads/enb.conf

sudo srsue ~/Downloads/ue.conf
```

Execute the GRC and force handover via gently moving cell gain levels

![Handover](/images/handover01.png)

## Cleanup

- For a clean tear down, the UE needs to be terminated first, then the eNB.
- eNB and UE can only run once, after the UE has been detached, the eNB needs to be restarted.
