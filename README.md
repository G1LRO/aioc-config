# AIOC Config — Pre-built Raspberry Pi Image

A ready-to-use Raspberry Pi image for configuring the [G1LRO hardware COS variant of the AIOC (All-In-One Cable)](https://g1lro.uk/?p=828) and also [virtual COS](https://g1lro.uk/?p=842).

The image comes with everything pre-installed — Python virtual environment, `aioc-util.py` from Hrafnkell Eiríksson, AIOC firmware v1.3.0, and a flash script — so you can be up and running in minutes without manual setup.

---

## What's Included

- [`aioc-util.py`](https://github.com/hrafnkelle/aioc-util/tree/main) — AIOC configuration utility (pre-installed with Python venv)
- `aioc-fw-1.3.0.bin` — AIOC firmware image
- `1.3flash.sh` — Script to flash/re-flash the firmware
- `direnv` configured so the Python venv activates automatically when you `cd` into the `~/aioc-util` directory

---

## Getting Started

### 1. Download the Image

Download `aiocutil.img.gz` from this repository's [releases](https://github.com/G1LRO/aioc-config/releases).

### 2. Flash to a microSD Card

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/):

1. Open Raspberry Pi Imager
2. Click **Choose OS → Use custom** and select the downloaded `aiocutil.img.gz`
3. Choose your microSD card as the target
4. Click the **settings** before writing — this lets you:
   - Set your own **username and password** (default: user `rln`, password `radioless`)
   - Configure your **Wi-Fi network**
   - Set your **hostname** and **locale** if needed
5. Click **Write**

> **Important:** It is strongly recommended to change the default password via Raspberry Pi Imager before writing, or on first boot using `passwd`.

### 3. Boot and Connect

Insert the microSD card into your Raspberry Pi and power it on. Once booted, connect using PUTTY or via SSH:

```bash
ssh rln@<your-pi-ip-address>
```

Or, if you set a custom hostname (e.g. `aioc`):

```bash
ssh rln@aioc.local
```

---

## Using aioc-util

### Activate the Environment

Simply change into the `aioc-util` directory — `direnv` will activate the Python virtual environment automatically:

```bash
cd ~/aioc-util
```

You should see a message like `direnv: loading .envrc`. The `aioc-util.py` command is now ready to use.

### Common Commands

**Enable hardware COS** (G1LRO AIOC variant):

```bash
./aioc-util.py --enable-hwcos --store
```

**Enable virtual COS** (standard/default behaviour):

```bash
./aioc-util.py --enable-vcos --store
```

> Always add `--store` to save settings to flash, otherwise they will be lost on reboot.

**View all current register values:**

```bash
./aioc-util.py --dump
```

**View audio settings:**

```bash
./aioc-util.py --audio-get-settings
```

**Set audio RX gain and TX boost:**

```bash
./aioc-util.py --audio-rx-gain 2x --audio-tx-boost on --store
```

**Restore hardware defaults:**

```bash
./aioc-util.py --defaults --store
```

### Full Help

```bash
./aioc-util.py --help
```

---

## Flashing / Re-flashing the AIOC Firmware

If you need to re-flash the AIOC firmware (v1.3.0), use the included script:

```bash
cd ~/aioc-util
./1.3flash.sh
```

The script will loop, watching for the AIOC to appear in DFU mode on USB. To enter DFU mode on the AIOC:

1. for new AIOC boards, bridge the programming jumper on the AIOC while plugging it into USB, **or**
2. The flash untiity will find and existing AIOC with firmware and re-flash the 1.3 image

Once flashing succeeds, the script will prompt you to unplug the device. Press `Ctrl+C` to exit the loop or the flash process will repeat. Do not interrrupt the process or unplug during the flash, wait for completion and then halt the process 'Ctrl-C'.

---

## Default Login Credentials

| Setting  | Default      |
|----------|-------------|
| Username | `rln`       |
| Password | `radioless` |

These can (and should) be changed during the Raspberry Pi Imager write process, or afterwards with the `passwd` command.

---

## Further Reading

- [G1LRO Hardware COS AIOC](https://g1lro.uk/?p=828)
- [G1LRO Virtual COS](https://g1lro.uk/?p=842)
- [aioc-util upstream repository](https://github.com/hrafnkelle/aioc-util/tree/main)
