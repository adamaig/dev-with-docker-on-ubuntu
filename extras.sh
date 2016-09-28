#!/bin/bash

echo "** INSTALLING support software for development"
sudo apt-get install -y zsh vim tmux fonts-powerline nodejs-legacy ruby \
  golang-go silversearcher-ag imagemagick
sudo fc-cache -vf # to activate the fonts: see http://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin

echo "** INSTALLING oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "** INSTALLING NVM"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.7/install.sh | bash

echo "** INSTALLING RVM"
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable

echo "** Setting up ssh keys and hosts"
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh-keyscan github.com bitbucket.org >> ~/.ssh/known_hosts

[[ -f ~/localextras.sh ]] && bash ~/localextras.sh

echo "** Consider installing MySQL, PostgreSQL, and Redis"
# sudo apt-get install -y postgresql libpq-dev redis-server mysql-server

# If there are problems with font configuration this may help
#sudo dpkg-reconfigure console-setup

