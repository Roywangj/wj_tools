#!/bin/bash
# Install screen and nvitop

sudo apt update
sudo apt install -y screen git
sudo apt install -y python3-pip
pip3 install --break-system-packages nvitop # ubuntu24.04

echo "Done! Usage:"
echo "  screen -S <name>   # new session"
echo "  screen -ls         # list sessions"
echo "  screen -r <name>   # reattach session"
echo "  nvitop             # GPU monitor"
