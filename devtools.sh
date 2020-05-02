#!/bin/bash

echo "** INSTALLING minimal support software for development"
sudo apt-get install -y -qq build-essential git zsh vim tar wget curl

echo "Add customizations to devtools-personal.sh"
[[ -f ~/devtools-personal.sh ]] && bash ~/devtools-personal.sh


