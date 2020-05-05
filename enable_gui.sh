#!/bin/bash

echo "** Installing unity desktop"
sudo apt-get install -y virtualbox-guest-x11 unity ubuntu-desktop

echo "** Setting password to username for login"
echo `whoami`:`whoami` | sudo chpasswd

echo "** Please remember to reboot to start the gui"

