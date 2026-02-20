# AIOC Config — Pre-built Raspberry Pi Image

A ready-to-use Raspberry Pi image for configuring the [G1LRO hardware COS variant of the AIOC (All-In-One Cable)](https://g1lro.uk/?p=828) and also [virtual COS](https://g1lro.uk/?p=842).

The image comes with everything pre-installed — Python virtual environment, `aioc-util.py` (a magical AIOC Config program from Hrafnkell Eiríksson), AIOC firmware v1.3.0, and a flash script — so you can be up and running in minutes without manual setup.

---

## What's Included

- [`aioc-util.py`](https://github.com/hrafnkelle/aioc-util/tree/main) — AIOC configuration utility (pre-installed with Python venv)
- `aioc-fw-1.3.0.bin` — AIOC firmware image
- `1.3flash.sh` — Script to flash/re-flash the firmware
- `direnv` configured so the Python venv activates automatically when you `cd` into the `~/aioc-util` directory

---

## Getting Started

### 1. Download the Image

Download `aiocutil.img.gz` from this repository.

### 2. Flash to a microSD Card

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/):

1. Open Raspberry Pi Imager
2. Click **Choose OS → Use custom** and select the downloaded `aiocutil.img.gz`
3. Choose your microSD card as the target
4. Click the settings before writing — this lets you:
   - Set your own **username and password** (default: user `rln`, password `radioless`)
   - Configure your **Wi-Fi network**
   - Set your **hostname** and **locale** if needed
5. Click **Write**

> **Important:** It is strongly recommended to change the default password via Raspberry Pi Imager before writing, or on first boot using `passwd`.

### 3. Boot and Connect

Insert the microSD card into your Raspberry Pi and power it on. Once booted, connect via SSH:

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

1. Hold the boot button on the AIOC while plugging it into USB, **or**
2. Run `./aioc-util.py --reboot` while the device is connected

Once flashing succeeds, the script will prompt you to unplug the device. Press `Ctrl+C` to exit the loop.

---

## Default Login Credentials

| Setting  | Default      |
|----------|-------------|
| Username | `rln`       |
| Password | `radioless` |

These can (and should) be changed during the Raspberry Pi Imager write process, or afterwards with the `passwd` command.

---

## udev Rules — Allowing HID Access to the AIOC

The AIOC presents itself to Linux as both a USB audio device and a HID (Human Interface Device). The HID interface is what `aioc-util.py` uses to read and write configuration registers. By default on most Linux systems, access to HID devices is restricted to root, which means running `aioc-util.py` as a regular user will fail with a permission error.

To fix this, you need a **udev rule** — a small configuration file that tells Linux to grant your user (or a group) permission to access the device when it is plugged in.

Create a new rules file:

```bash
sudo nano /etc/udev/rules.d/99-aioc.rules
```

Add the following line:

```
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="7388", MODE="0660", GROUP="plugdev"
```

What this does: whenever the AIOC is plugged in (`idVendor` and `idProduct` identify it uniquely), Linux sets the permissions on its HID device node so that members of the `plugdev` group can read and write it. The `plugdev` group is the conventional group for this purpose on Debian-based systems.

Make sure your user is a member of `plugdev`:

```bash
sudo usermod -aG plugdev $USER
```

Then reload the udev rules and re-trigger them (or simply unplug and replug the AIOC):

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

You will need to log out and back in (or start a new SSH session) for the group membership change to take effect.

> **Note:** If you changed the AIOC's USB VID/PID using `--set-usb` (e.g. to emulate a CM108), update the `idVendor` and `idProduct` values in the rule to match the new values.

---

## AllStarLink 3

Setting up an [AllStarLink](https://www.allstarlink.org/) node with the AIOC is straightforward. ASL3 has built-in support for the AIOC's default USB VID/PID values, so in most cases you won't need to change the device identity at all.

A setup script `setup-asl3.sh` is included in this repository that performs all four steps below in one go:

```bash
wget https://raw.githubusercontent.com/G1LRO/aioc-config/refs/heads/main/setup-asl3.sh
chmod +x setup-asl3.sh
./setup-asl3.sh
```

> After running the script for the first time, log out and back in (or start a new SSH session), then unplug and replug the AIOC to ensure the udev and group changes take effect.

If you'd prefer to run the steps manually, they are:

### 1. udev Rule

Make sure the udev rule described above is in place so that ASL3 can access the AIOC's HID interface for COS detection and PTT control.

### 2. Set the VCOS Timing Register

If you are using virtual COS, set the `VCOS_TIMCTRL` register to 1500. This controls the squelch tail timing and gives reliable COS behaviour with ASL3:

```bash
cd ~/aioc-util
./aioc-util.py --vcos-timctrl 1500 --store
```

### 3. Configure res_usbradio

The AIOC's USB VID/PID is already present in `/etc/asterisk/res_usbradio.conf` but commented out. Uncomment it with this one-liner:

```bash
sudo sed -i 's/^;usb_devices = 1209:7388/usb_devices = 1209:7388/' /etc/asterisk/res_usbradio.conf
```

Then restart Asterisk:

```bash
sudo systemctl restart asterisk
```

### 4. Optional — Change VID/PID to Emulate a CM108

If you prefer to make the AIOC appear as a standard CM108 interface (for example, for compatibility with other software), you can change its USB identity:

```bash
./aioc-util.py --set-usb 0x0d8c 0x000c --store
```

Note that if you do this, you will need to update your udev rule to match the new VID/PID, and you should use the standard CM108 entry in `res_usbradio.conf` instead of the AIOC-specific one.

---

## Further Reading

- [G1LRO Hardware COS AIOC](https://g1lro.uk/?p=828)
- [G1LRO Virtual COS](https://g1lro.uk/?p=842)
- [aioc-util upstream repository](https://github.com/hrafnkelle/aioc-util/tree/main)
