#!/bin/bash

echo "** INSTALLING support software for development"
sudo add-apt-repository -y ppa:jonathonf/vim
sudo apt-get update -y
sudo apt-get install -y zsh vim xauth xclip \
  mysql-client libmysqlclient-dev \
  postgresql-client libpq-dev \
  sqlite3 libbz2 \
  tar wget curl libevent-dev libncurses-dev

echo "** INSTALLING tmux 2.6 from source"
sudo apt-get -y remove tmux
VERSION=2.6 && mkdir ~/tmux-src && \
  wget -qO- https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz | tar xvz -C ~/tmux-src && \
  cd ~/tmux-src/tmux* && \
  ./configure && make -j"$(nproc)" && \
  sudo make install && \
  cd ~ && rm -rf ~/tmux-src

[[ -f ~/localextras.sh ]] && bash ~/localextras.sh

