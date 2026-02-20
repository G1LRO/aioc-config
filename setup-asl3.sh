#!/bin/bash
# setup-asl3.sh — Configure the AIOC for use with AllStarLink 3
set -e

echo "==> Step 1: Installing udev rule for AIOC HID access..."
sudo tee /etc/udev/rules.d/99-aioc.rules > /dev/null <<'EOF'
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="7388", MODE="0660", GROUP="plugdev"
EOF
sudo usermod -aG plugdev "$USER"
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "    Done. You may need to log out and back in for group changes to take effect."

echo "==> Step 2: Setting VCOS_TIMCTRL register to 1500..."
cd ~/aioc-util
./aioc-util.py --vcos-timctr 1500 --store
echo "    Done."

echo "==> Step 3: Enabling AIOC in res_usbradio.conf..."
sudo sed -i 's/^;usb_devices = 1209:7388/usb_devices = 1209:7388/' /etc/asterisk/res_usbradio.conf
echo "    Done."

echo "==> Step 4: Restarting Asterisk..."
sudo systemctl restart asterisk
echo "    Done."

echo ""
echo "Setup complete. If this is your first time running this script,"
echo "please log out and back in to ensure plugdev group access is active,"
echo "then unplug and replug the AIOC."
