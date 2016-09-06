#!/bin/bash

echo "** Setting up ssh keys and hosts"
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ssh-keyscan github.com bitbucket.org >> ~/.ssh/known_hosts
