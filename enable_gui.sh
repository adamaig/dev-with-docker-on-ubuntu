#!/bin/bash

echo "** Installing RubyMine"
RUBYMINE_VERSION="RubyMine-2016.3.2"
wget https://download.jetbrains.com/ruby/${RUBYMINE_VERSION}.tar.gz
tar zxf ${RUBYMINE_VERSION}.tar.gz && rm  ${RUBYMINE_VERSION}.tar.gz

echo "** Installing unity desktop"
sudo apt-get install -y virtualbox-guest-x11 unity ubuntu-desktop

echo "** Setting password to username for login"
echo `whoami`:`whoami` | sudo chpasswd

echo "** Please remember to reboot to start the gui"

