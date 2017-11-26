#!/bin/bash

echo "** INSTALLING support software for development"
sudo add-apt-repository -y ppa:jonathonf/vim
sudo apt-get update -y
sudo apt-get install -y zsh vim fonts-powerline \
  nodejs-legacy ruby golang-go python-dev python-pip \
  silversearcher-ag imagemagick xauth xclip \
  mysql-client postgresql-client \
  libmysqlclient-dev libpq-dev

echo "** INSTALLING tmux 2.6 from source"
sudo apt-get -y remove tmux
sudo apt-get install -y wget tar libevent-dev libncurses-dev
VERSION=2.6 && mkdir ~/tmux-src && \
  wget -qO- https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz | tar xvz -C ~/tmux-src && \
  cd ~/tmux-src/tmux* && \
  ./configure && make -j"$(nproc)" && \
  sudo make install && \
  cd ~ && rm -rf ~/tmux-src

pip install --upgrade pip

sudo fc-cache -vf # to activate the fonts: see http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin

if [[ ! -d ~/.oh-my-zsh ]]
then
  echo "** INSTALLING oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if [[ ! -d ~/.nvm ]]
then
  echo "** INSTALLING NVM"
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
fi

if [[ ! -d ~/.rvm ]]
then
  echo "** INSTALLING RVM"
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  \curl -sSL https://get.rvm.io | bash -s stable
fi

[[ -f ~/localextras.sh ]] && bash ~/localextras.sh

echo "** Consider installing MySQL, PostgreSQL, and Redis"
# sudo apt-get install -y postgresql libpq-dev redis-server mysql-server

# If there are problems with font configuration this may help
#sudo dpkg-reconfigure console-setup

