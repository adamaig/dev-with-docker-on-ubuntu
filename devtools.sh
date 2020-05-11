#!/bin/bash

echo "** INSTALLING support software for development"
sudo apt-get install -y \
  git zsh vim xauth xclip tar wget curl \
  build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev libssl-dev libreadline-dev libffi-dev libbz2-dev \
  libevent-dev libncurses-dev \
  mysql-client libmysqlclient-dev \
  postgresql-client libpq-dev \
  sqlite3 libsqlite3-dev

echo "Add customizations to devtools-personal.sh"
[[ -f ~/devtools-personal.sh ]] && chmod +x ~/devtools-personal.sh && bash ~/devtools-personal.sh
