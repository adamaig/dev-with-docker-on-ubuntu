#!/bin/sh

# When your vagrant disk reaches its maximum capacity, run this script to remove any unused images and volumes to free up some space.
# TODO: move this file into vagrant

echo "** Listing the current status of the disk space in your vagrant box"
df -h

echo "** Removing the following unused images: "
docker rmi $(docker images -f dangling=true -q)

echo "** Removing the following unusued volumes: "
docker volume rm $(docker volume ls -f dangling=true -q)

echo "** Listing the updated status of the disk space in your vagrant box"
df -h

