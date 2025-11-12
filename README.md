# dev-with-docker-on-ubuntu

*Update*: As docker-desktop and other innovations have largely solved the problems this tooling addressed, this is being archived.

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
_you do not need the docker-machine to be up_. It may cause problems, and has
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

Many configuration options are available by setting up a `config.yml` file.
This file is processed with ERB before loading, allowing use of ruby scripting
to configure values. I found that I wanted to build experimental boxes, but
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
  1. `ssh 192.168.90.10` if using the default ip setting (use config.yml's vm.ip otherwise), _OR_
  1. `vagrant ssh` and then `sudo su -l <username>` in the box, _OR_
  1. `ssh localhost -X -p $(vagrant ssh-config | awk '/Port/ { print $2;}')`
- Edit files in ~\$USER/vagrant_project

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

The model in this project is based around these assumptions:

- If you're developing on OSX, you may have a shell config that you'd be
  comfortable using in a linux context.
- Using NFS to share files between host and guest is reasonably fast, and if
  the slowness is in editor actions, that is preferable to awkward setups that
  cause issues with switching git branches, slowdown code compilation, disable
  fs event watching, or result in slow webapp/webpage load times.

# Additional Docs

1. [DNS](./docs/dns.md)
1. [Clipboard Support](./docs/clipboard_support.md)
1. [Resizing VBox Disks](./docs/resizing_vbox_disks.md)

# Known Issues

1. Be careful when halting the guest if you have the NFS share mounted, particularly
   if you use Alfred, as halting the box or other network disruptions may cause the
   Finder or other filesystem interaction to freeze while waiting on the mount to
   timeout. **If this occurs, a) unmount the share, and if that fails b) restart the
   guest, and unmount the share before halting.** Don't panic!
2. The box this project is based on is older, so you may wish to start by specifying
   a newer box version, or run `apt-get dist-upgrade` to bring the system more up to date.
3. To upgrade the kernel: `apt-get install --install-recommends linux-generic-hwe-16.04 xserver-xorg-hwe-16.04`
