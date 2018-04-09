# dev-with-docker-on-ubuntu

After fighting with Docker on OSX and the need for 2-way syncs, fsevents, etc.
I developed a desire to get back to a simple(r) development on a linux based
VM. This project is a jumping off point.

# Features

This project provides easily configurable box building with:

- Docker
  - Docker-daemon tweaks via Systemd configs.
  - Docker & docker-compose installed and configured
- Routing
 - OSX routing and resolver based dns lookups for your docker domains
 - dnsmasq routing to you docker containers in the guest
 - Provides a Consul & Registrator setup for DNS communication and discovery.
- Editing
  - NFS sharing from the guest to the host to support live editing AND file
    eventing for build systems (guard, webpack, etc)
  - Generates script `mount_nfs_share` to remount drive and setup routes to
    host if it is disconnected
- User provisioning
  - Auto-configuration of a limited clone of the user running `vagrant up`. SSH keys
    are copied to a user created with the same name as the host user.
  - Extensible by editing localextras.sh to meet needs of cloned user

# Usage

## Terminology

- The guest is the Vagrant Ubuntu box.
- The Host is the OSX box where `vagrant up` is run.
- The user is the user executing the `vagrant up` command.

## Prerequisites

Both vagrant and virtualbox must be available. You may also want to install
docker and docker-compose in order to run docker commands from the host, but
*you do not need the docker-machine to be up*. It may cause problems, and has
not been tested in conjunction with this repo, as this project is an attempt
to replace the docker-machine.

## Basic Setup

- Install vagrant either via download or homebrew.
- Copy localextras.sh.example to localextras.sh
- Edit localextras.sh to configure the user's configuration in the guest. You
  may also wish to edit extras.sh
- In this project directory run `vagrant up`. After a few minutes, the user
  will be prompted to enter their password for the host. This will run a few
  commands on the host to setup DNS routing for the .docker domain to the guest.
  See OSX's documenation on /etc/resolver/ files (i.e., `man 5 resolver`).

### Advanced Setup

Many configuration options are available by setting up a ``config.yml`` file.
This file is processed with ERB before loading, allowing use of ruby scripting
to configure values.  I found that I wanted to build experimental boxes, but
needed them to run on different ips, and have different NFS mounts, or use
different domain names for routing. The options are documented in the Vagrant
file.

```
user:
  username:                            # Sets the user to create
  shell:                               # Sets the login shell of the user
enable_gui: true                       # Enable/disable the gui: true, false
vm:
  name: "dev-on-ub"                    # Sets the name of the vagrant guest
  ip: 192.168.90.10                    # Sets the private ip of the guest. Used for routing
  gateway_ip: 192.168.90.1             # Sets the gateway for the guest. Used for NFS mount sharing
  cpus: 4                              # Passed to `VBoxManage modifyvm` to configure guest resources
  memory: 8192                         # ditto
  vram: 64                             # ditto
  accelerate_3d: on                    # ditto
  clipboard: bidirectional             # ditto
  draganddrop: hosttoguest             # ditto
tz: UTC                                # Timezone to setup
docker:
  bridge_ip: 172.17.0.1                # Sets docker daemon brige ip
  subnet_ip: 172.17.0.0                # Sets docker daemon subnet ip. Used for DNS routing
  subnet_mask: 16                      # Sets docker daemon subnet mask. Used for DNS routing
consul:
  dns_port: 8600                       # Sets the DNS port for consul in dnsmasq and resolver configs
  domain: docker                       # ditto
nfs:
  mount_on_up: true                    # Enable/disable mounting NFS share on guest up: true, false
  directory_name: vagrant_projects     # Specifies name of directory for mount and share
```

## Access & Workflow
- Connect to the vagrant guest as the user by either
  1. `ssh 192.168.90.10` if using the default ip setting (use config.yml's vm.ip otherwise), *OR*
  1. `vagrant ssh` and then `sudo su -l <username>` in the box, *OR*
  2. `ssh localhost -X -p $(vagrant ssh-config | awk '/Port/ { print $2;}')`
- Edit files in ~$USER/vagrant_project

## Using Consul for \*.docker DNS resolution

In order to leverage name resolution for containers from the host, we use consul
and registrator. The initial Vagrant provision script sets up the OSX domain
resolver, but we still need to run a docker container inside the guest to
complete the flow.

- Connect to the guest as described above
- `cd ~/consul-registrator-setup && docker-compose up -d`
- Open a browser and visit http://consul.service.docker:8500 and you should
  see the consul ui

At this point you should also be able to ping the service as well. For other
docker-compose based projects you can make them available by following patterns
similar the one shown in `examples/webapp/docker-compose.yml`

## Notes on using docker-compose

### Use DOCKER_HOST env var to communicate from host to guest daemon

After provisioning the machine, run `export DOCKER_HOST="tcp://[guest ip]:2375"`
in order to allow local docker tools to communicate to the docker daemon on
the guest.

### In the guest /Users is symlinked to /home

By creating a symlink from /Users to /home in the guest, `docker-compose` files
that use relative paths for volumes (i.e., `.:/home/app/myapp:rw`) will function
as expected when paths are expanded on either the host or guest. Note that this
requires the full path, `/User/<username>/vagrant_projects/path/to/code`, be
available in both guest and host.

# Assumptions

After working with the default docker-machine setup, and exploring a 2-way rsync
triggered by changes on the host, I decided I'd rather work with a standard linux
box setup that we might use in production. The underlying Vagrant setup could be
modified to use CentOS and yum, but I chose to use Ubuntu for now.

The fundamental model is based around these assumptions:
- If you're developing on OSX, you may have a shell config that you'd be
  comfortable using in a linux context.
- Using NFS to share files between host and guest is reasonably fast, and if
  the slowness is in editor actions, that is preferable to awkward setups that
  cause issues with switching git branches, slowdown code compilation, disable
  fs event watching, or result in slow webapp/webpage load times.

# Resizing VBox disks

The VMDK format cannot be resized currently (2017-03-05), but it is possible to
clone the drive to the VDI format, and increase the max size of the disk. The
VM must be off in order for this process to execute.

In this example a new 60GB disk will be created.

1. Start downloading the gparted live cd. The version specified is current as of 2017-05,
   and the correct variant of the live CD for a 64bit MacBook Pro.
   ```shell
   wget http://downloads.sourceforge.net/gparted/gparted-live-0.28.1-1-amd64.iso
   # OR
   curl -L -O http://downloads.sourceforge.net/gparted/gparted-live-0.28.1-1-amd64.iso
   ```

2. If the download is continuing, open a new terminal. Stop the vagrant guest,
   clone the existing disk to a new format, resize the disk, and then swap the
   VM's disk in place.

   ```shell
   # Halt the system if it is running
   vagrant halt

   # clone the drive to a new format:
   VBoxManage clonemedium disk \
     ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vmdk \
     ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi --format vdi

   # Resize it to desired size (e.g., 60GB here):
   VBoxManage modifymedium ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi \
     --resize $(expr 60 \* 1024)

   # Replace the original drive:
   VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 0 \
     --device 0 --type hdd  --medium ~/VirtualBox\ VMs/dev-on-ub/ubuntu-16.04-amd64-disk1.vdi
   ```

3. Configure the boot order (1: optical drive; 2: disk):
   ```shell
   VBoxManage modifyvm dev-on-ub --boot1 dvd --boot2 disk
   ```

4. After running this it may be necessary to restart the box a few times in
   order to get the VM to fully boot up cleanly. It isn't clean but, I found that
   "powercycling" it when it got stuck or issuing a `vagrant halt` command would
   lead to a clean boot after the VM gets stuck.

   Once you have a clean boot up with the new disk attached, and you can proceed
   to modify the partition table so that the new disk space can be used.

5. Attach optical drive w/ cd:
   ```shell
   VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 1 \
     --device 0 --type dvddrive --medium ./gparted-live-0.28.1-1-amd64.iso
   ```

   Note that the disk will be ejected after rebooting. Repeat this step if
   needed.

6. Now everything is ready to boot.
   ```shell
   VBoxManage startvm dev-on-ub --type gui
   ```

7. Follow the prompts in GParted until a GUI appears.
   Choose not to modify the keymap, then select a language you want, then continue
   through the remaining prompts. If GParted does not start automatically, start it.

   Note the partition device and mount point for the next step. In this example,
   these are /dev/sda5 and vagrant--vg-root.

   You will need to "deactivate" the existing partitions (right click to open menu),
   this will remove the locks, then right click the partition you want to resize
   and modify the partition size as desired. Apply the changes.

   This process must be done twice. Once to resize the extended partition so
   that it can use all the space on the physical disk, and again to resize the
   child of the extended partition, /dev/sda5, so that it can use all the space
   in the parent partition.

7. Close the GParted application, then open the terminal (do not reboot) and
   run the following commands. Note the double dash in 'vagrant--vg-root'.

   ```shell
   sudo pvresize /dev/sda5
   sudo lvresize -l +100%FREE /dev/mapper/vagrant-–vg-root
   sudo e2fsck -f /dev/mapper/vagrant-–vg-root
   sudo resize2fs /dev/mapper/vagrant-–vg-root
   ```

8. Shutdown the machine.
9. If the disk isn't automatically ejected, Eject the ISO in the optical drive:

   ```shell
   VBoxManage storageattach dev-on-ub --storagectl "SATA Controller" --port 1 \
     --device 0 --type dvddrive --forceunmount --medium emptydrive
   ```

Reboot the virtualbox. It may require a few reboots and/or powercycles as before.

# Clipboard Support

For Mac, in order to use the clipboard across the host and the guest vagrant box, you must:

1. Download and run [XQuartz](https://www.xquartz.org/)
1. Forward X11 in your ssh connection:

  ```shell
    Host localhost
      ...
      ForwardX11 yes
  ```
  or pass the ``-X`` flag to the ssh connection string

  ``ssh user@host -X``

## Add Support for `pbcopy` and `pbpaste`

If you prefer to use `pbcopy` and `pbpaste` within the vagrant box just add the following to your shell config.

```shell
# .zshrc or .bashrc
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
```

## Add Clipboard Support to Tmux

```shell
# .tmux.conf
if-shell "uname -n | grep vagrant" \
  'bind-key -t vi-copy Enter copy-pipe "xclip -in -selection clipboard"'
```

# Known Issues

1. Be careful when halting the guest if you have the NFS share mounted, particularly
if you use Alfred, as halting the box or other network disruptions may cause the
Finder or other filesystem interaction to freeze while waiting on the mount to
timeout. **If this occurs, a) unmount the share, and if that fails b) restart the
guest, and unmount the share before halting.** Don't panic!
2. The box this project is based on is older, so you may wish to start by specifying
a newer box version, or run `apt-get dist-upgrade` to bring the system more up to date.
3. To upgrade the kernel: `apt-get install --install-recommends linux-generic-hwe-16.04 xserver-xorg-hwe-16.04`

