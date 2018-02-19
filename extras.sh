#!/bin/bash

echo "** INSTALLING support software for development"
sudo add-apt-repository -y ppa:jonathonf/vim
sudo apt-get update -y
sudo apt-get install -y zsh vim xauth xclip \
  mysql-client libmysqlclient-dev \
  postgresql-client libpq-dev \
  tar wget curl libevent-dev libncurses-dev

echo "** INSTALLING tmux 2.6 from source"
sudo apt-get -y remove tmux
VERSION=2.6 && mkdir ~/tmux-src && \
  wget -qO- https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz | tar xvz -C ~/tmux-src && \
  cd ~/tmux-src/tmux* && \
  ./configure && make -j"$(nproc)" && \
  sudo make install && \
  cd ~ && rm -rf ~/tmux-src

echo "** INSTALLING common programming packages"
sudo apt-get install -y nodejs-legacy ruby golang-go python-dev python-pip
pip install --upgrade pip

[[ -f ~/localextras.sh ]] && bash ~/localextras.sh

echo "** Consider installing MySQL, PostgreSQL, and Redis"
# sudo apt-get install -y postgresql libpq-dev redis-server mysql-server

# If there are problems with font configuration this may help
#sudo dpkg-reconfigure console-setup

