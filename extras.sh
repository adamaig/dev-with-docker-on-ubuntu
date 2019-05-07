#!/bin/bash

echo "** INSTALLING support software for development"
sudo add-apt-repository ppa:git-core/ppa
sudo add-apt-repository -y ppa:jonathonf/vim
sudo apt-get update -y
sudo apt-get install -y git zsh vim xauth xclip tar wget curl \
  build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev libssl-dev libreadline-dev libffi-dev libbz2-dev \
  libevent-dev libncurses-dev \
  mysql-client libmysqlclient-dev \
  postgresql-client libpq-dev \
  sqlite3 libsqlite3-dev

echo "** INSTALLING tmux 2.7 from source"
sudo apt-get -y remove tmux
VERSION=2.7 && mkdir ~/tmux-src && \
  wget -qO- https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz | tar xvz -C ~/tmux-src && \
  cd ~/tmux-src/tmux* && \
  ./configure && make -j"$(nproc)" && \
  sudo make install && \
  cd ~ && rm -rf ~/tmux-src

[[ -f ~/localextras.sh ]] && bash ~/localextras.sh

