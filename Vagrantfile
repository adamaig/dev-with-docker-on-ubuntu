# frozen_string_literal: true
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'erb'
require 'pp'

# Default configuration options
config_options = {
  "user" => {
    "username" => ENV.fetch('USER'),
    "shell" => ENV.fetch('SHELL')
  },
  "enable_gui" => false,
  "vm" => {
    "name" => "dev-on-ub",
    "ip" => "192.168.90.10",
    "gateway_ip" => "192.168.90.1",
    "cpus" => 4,
    "memory" => 4096,
    "vram" => 64,
    "accelerate_3d" => "off",
    "clipboard" => "bidirectional",
    "draganddrop" => "hosttoguest"
  },
  "tz" => "UTC",
  "docker_bridge" => {"ip" => "172.17.0.1", "mask" => 16},
  "docker_subnet" => {"ip" => "172.16.0.0", "mask" => 12},
  "consul" => {"dns_port" => 8600, "domain" => "docker"},
  "nfs" => {
    "mount_on_up" => true,
    "directory_name" => "vagrant_projects",
    "host_mount_options" => "rw,bg,hard,nolocks,intr,sync"
  },
  "local_backup" => "~/vagrant_project.bkup"
}

class Hash
  def options_merge(other)
    self.merge(other) do |key, self_v, other_v|
      if self_v.is_a?(Hash)
        self_v.options_merge(other_v)
      else
        other_v.nil? ? self_v : other_v
      end
    end
  end
end

# Read option file if it exists
if File.exist?("config.yml")
  config_yaml = YAML.load(ERB.new(File.read("config.yml")).result)
  config_options = config_options.options_merge(config_yaml)
  puts "** Running with options:"
  pp config_options
end

# Specifies the docker-engine apt package version
DOCKER_ENGINE_VERSION="5:19.03.8~3-0~ubuntu-bionic"
# Specifies the docker-compose release version
DOCKER_COMPOSE_VERSION="1.25.5"

# Set this to true in order to enable the gui and install necessary packages
ENABLE_GUI = config_options["enable_gui"]

# VM_NAME specifies the box name that will appear in virtualbox.
VM_NAME = config_options["vm"]["name"]

# VM_IP specifies the port the VM will run on, and the routes
VM_IP = config_options["vm"]["ip"]

# VM_GATEWAY_IP specifies the NFS export access. Corresponds to the host's IP
# in the vboxnet
VM_GATEWAY_IP = config_options["vm"]["gateway_ip"]

# Used to specify subet used by the docker engine bridge network
DOCKER_BRIDGE_IP = config_options["docker_bridge"]["ip"]
DOCKER_BRIDGE_MASK = config_options["docker_bridge"]["mask"]
DOCKER_BRIDGE_CIDR = "#{DOCKER_BRIDGE_IP}/#{DOCKER_BRIDGE_MASK}"

# Specifies the OSX route to the docker subnet
DOCKER_SUBNET_IP = config_options["docker_subnet"]["ip"]
DOCKER_SUBNET_MASK = config_options["docker_subnet"]["mask"]
DOCKER_SUBNET_CIDR = "#{DOCKER_SUBNET_IP}/#{DOCKER_SUBNET_MASK}"

# This value should match the port that maps to consul 8600 in the docker-compose
CONSUL_DNS_PORT = config_options["consul"]["dns_port"]
# Used by dnsmasq for to route dns queries to consul
CONSUL_DOMAIN = config_options["consul"]["domain"]

# Mounts NFS share after machine is up if true
NFS_MOUNT_ON_UP = config_options["nfs"]["mount_on_up"]
# Name of the directory used for the NFS mount
NFS_MOUNT_DIRNAME = config_options["nfs"]["directory_name"]
# NFS client/host mount options
NFS_HOST_MOUNT_OPTS = config_options["nfs"]["host_mount_options"]
# Directory for caching work NFS export to the host for safety
LOCAL_NFS_SYNC_DIR = config_options["local_backup"]

# This var will be used to configure the user created in the vagrant, and
# should match the user running the vagrant box
USERNAME = config_options["user"]["username"]
SHELL = config_options["user"]["shell"]

# The timezone for the box
TIMEZONE = config_options["tz"]

# These HEREDOCs are additional config files used to setup the docker development
# environment and dns lookups
dnsmasq_base_conf = <<EOF
# Add listener for systemd-resolved
listen-address=127.0.0.2
# add listener for configured ip
listen-address=#{VM_IP}
EOF

dnsmasq_docker_conf = <<EOF
# add listener for docker daemon bridge
listen-address=#{DOCKER_BRIDGE_IP}
# point DNS resolution for domain to consul
server=/.service.#{CONSUL_DOMAIN}/127.0.0.1##{CONSUL_DNS_PORT}
EOF

# The systemd dropin config for the docker service
docker_drop_in_conf = <<EOF
[Unit]
# Ensure the docker bridge is up before starting dnsmasq
Before=dnsmasq.service

[Service]
# Reset the ExecStart values due to systemd quirk
ExecStart=
# Manage configuration options in /etc/docker/daemon.json
ExecStart=/usr/bin/dockerd
# Ensure traffic to containers is not dropped
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
EOF

docker_daemon_json = <<EOF
{
  "hosts": ["fd://", "tcp://0.0.0.0:2375"],
  "bip": "#{DOCKER_BRIDGE_CIDR}"
}
EOF

systemd_resolved_dnsmasq_conf = <<EOF
[Resolve]
DNS=127.0.0.2
EOF

# This script is emitted to allow easy reinstantiation of the OSX routes to the
# consul guests
osx_routes = <<EOF
#!/bin/bash

echo '** Adding resolver directory if it does not exist'
[[ ! -d /etc/resolver ]] && sudo mkdir -p /etc/resolver

echo '** Adding/Replacing *.docker resolver (replacing to ensure OSX sees the change)'
[[ -f /etc/resolver/#{CONSUL_DOMAIN} ]] && sudo rm -f /etc/resolver/#{CONSUL_DOMAIN}
sudo bash -c "printf '%s\n%s\n' 'nameserver #{VM_IP}' > /etc/resolver/#{CONSUL_DOMAIN}"

echo '** Adding routes'
sudo route -n delete #{DOCKER_SUBNET_CIDR} #{VM_IP}
sudo route -n add #{DOCKER_SUBNET_CIDR} #{VM_IP}
EOF

# This script is emitted to allow mounting the NFS share
mount_nfs = <<EOF
#!/bin/bash

echo '** Mounting ubuntu NFS /home/#{USERNAME}/#{NFS_MOUNT_DIRNAME} to ~/#{NFS_MOUNT_DIRNAME}'
[[ ! -d #{ENV.fetch('HOME')}/#{NFS_MOUNT_DIRNAME} ]] && mkdir #{ENV.fetch('HOME')}/#{NFS_MOUNT_DIRNAME} && touch #{ENV.fetch('HOME')}/#{NFS_MOUNT_DIRNAME}/.metadata_never_index
sudo mount -t nfs -o #{NFS_HOST_MOUNT_OPTS} #{VM_IP}:/home/#{USERNAME}/#{NFS_MOUNT_DIRNAME} #{ENV.fetch('HOME')}/#{NFS_MOUNT_DIRNAME}
EOF

File.open("./setup_routes", "w", 0700) { |f| f.puts osx_routes } unless File.exist?("./setup_routes")
File.open("./mount_nfs_share", "w", 0700) { |f| f.puts mount_nfs } unless File.exist?("./mount_nfs_share")

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu1804"
  config.vm.box_check_update = true

  # Make sure you have XQuartz running on the host
  config.ssh.forward_x11 = true

  # set the hostname to the name of the vm
  config.vm.hostname = VM_NAME

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: VM_IP

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name = VM_NAME
    vb.memory = config_options["vm"]["memory"]
    vb.cpus = config_options["vm"]["cpus"]

    if ENABLE_GUI
      vb.gui = true
      vb.customize ["modifyvm", :id, "--vram", config_options["vm"]["vram"]]
      vb.customize ["modifyvm", :id, "--accelerate3d", config_options["vm"]["accelerate_3d"]]
      vb.customize ["modifyvm", :id, "--clipboard", config_options["vm"]["clipboard"]]
      vb.customize ["modifyvm", :id, "--draganddrop", config_options["vm"]["draganddrop"]]
    end
  end

  config.vm.provision "base_setup", type: "shell", inline: <<-SHELL
    echo "** Configuring locale and timezone"
    update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" \
      LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" \
      LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"

    timedatectl set-timezone #{TIMEZONE}

    echo "*** Updating apt index"
    apt-get update -y
    apt-get install -y -qq --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      debconf-utils \
      gnupg-agent \
      software-properties-common

    echo "*** Installing base services: ntp"
    apt-get install -y -qq ntp

    echo "*** Installing tools: curl, wget, tar, build-essential, git, vim, sqlite"
    apt-get install -y -qq curl wget tar build-essential git vim sqlite

    echo "Reloading systemclt configs and restarting services"
    systemctl daemon-reload
    service ntp restart
  SHELL

  config.vm.provision "configure_dns_services", type: "shell", inline: <<-SHELL
    echo "*** Installing base services: dnsmasq, network-manager"
    apt-get install -y -qq network-manager dnsmasq

    echo "*** Reconfigure systemd-resolved, NetworkManager, and dnsmasq to work together"
    echo "*** Add dnsmasq to systemd-resolved DNS servers"
    mkdir /etc/systemd/resolved.conf.d
    echo "#{systemd_resolved_dnsmasq_conf}" > /etc/systemd/resolved.conf.d/dnsmasq.conf

    echo "*** Replace the stub-resolv.conf with the managed resolv.conf"
    rm /etc/resolv.conf
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    echo "*** Disable default settings in systemd-resolved conf"
    sed -i -e '/Resolve/,$ s/^[#]*\\(.*\\=\\)/#\\1/' /etc/systemd/resolved.conf

    echo "*** Add dnsmasq support for routing to localhost"
    echo "#{dnsmasq_base_conf}" > /etc/dnsmasq.d/10-base-dns

    systemctl daemon-reload
    service systemd-resolved restart
    service network-manager restart
    service dnsmasq restart
  SHELL

  config.vm.provision "install_docker", type: "shell", inline: <<-SHELL
    echo "*** Running setup from docker installation"
    # Remove any prior docker versions
    apt-get remove docker docker-engine docker.io containerd runc

    echo "*** Updating apt index"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -y

    echo "*** Installing Docker CE"
    apt-get install -y docker-ce=#{DOCKER_ENGINE_VERSION} \
      docker-ce-cli=#{DOCKER_ENGINE_VERSION} \
      containerd.io

    echo "*** Installing docker-compose version=#{DOCKER_COMPOSE_VERSION}"
    url_base="https://github.com/docker/compose/releases/download/"
    version="#{DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`"
    curl -s -L $url_base$version -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "creating admin and docker groups"
    groupadd -f docker
    groupadd -f admin
  SHELL

  config.vm.provision "docker_customization", type: "shell", inline: <<-SHELL
    echo "** Modifying NetworkManager and dnsmasq to support routing to service.docker"
    echo "#{dnsmasq_docker_conf}" > /etc/dnsmasq.d/11-docker

    echo "** Adding /etc/docker/daemon.json configuration"
    echo '#{docker_daemon_json}' >> /etc/docker/daemon.json

    echo "** Setting up systemd drop-in config for docker daemon"
    [ ! -d /etc/systemd/system/docker.service.d ] && mkdir /etc/systemd/system/docker.service.d
    echo "#{docker_drop_in_conf}" > /etc/systemd/system/docker.service.d/dev-on-docker.conf

    echo "Reloading systemctl configs and restarting services"
    systemctl daemon-reload
    service dnsmasq restart
    service docker restart

    echo "Add vagrant user to docker group"
    usermod -aG admin,docker vagrant

    echo "** Linking /Users -> /home in the guest. Supports volume mounting in docker-compose path expansion over the DOCKER_HOST tcp connection."
    [[ ! -L /Users ]] && ln -s /home /Users
    echo "*** completed docker_customization script"
  SHELL

  # User creation scripts
  config.vm.provision "create_user", type: "shell", inline: <<-SHELL
    apt-get install -y $(basename #{SHELL})
    [[ -z "$(getent passwd #{USERNAME})" ]] && adduser --force-badname --uid 9999 --shell=/bin/$(basename #{SHELL}) --disabled-password --gecos "#{USERNAME}" #{USERNAME}
    usermod -G docker,admin,sudo,staff #{USERNAME}
    # File is named dev_w_docker_user due to sudoers processing rules excluding some characters
    echo "#{USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev_w_docker_user
  SHELL

  USER_SETUP_TMP_DIR = "/tmp/user_setup"
  config.vm.provision "copy_user_ssh_files", type: "file", source: "~#{USERNAME}/.ssh", destination: "#{USER_SETUP_TMP_DIR}/.ssh"
  config.vm.provision "copy_consul_example", type: "file", source: "./consul-registrator-setup", destination: "#{USER_SETUP_TMP_DIR}/consul-registrator-setup"
  config.vm.provision "cp_dev_tool_script", type: "file", source: "./devtools.sh", destination: "#{USER_SETUP_TMP_DIR}/"
  if File.exist?("./devtools-personal.sh")
    config.vm.provision "cp_personal_dev_tool_script", type: "file", source: "./devtools-personal.sh", destination: "#{USER_SETUP_TMP_DIR}/"
  end
  config.vm.provision "mv_setup_files_to_user_dir", type: "shell", inline: <<-SHELL
    sudo cp -r #{USER_SETUP_TMP_DIR}/.ssh #{USER_SETUP_TMP_DIR}/* ~#{USERNAME}/
    sudo chown -R #{USERNAME}: ~#{USERNAME}
  SHELL

  config.vm.provision "setup_user_ssh", type: "shell", inline: <<-SHELL
    chmod 0700 ~#{USERNAME}/.ssh

    echo "** Cleaning up ssh authorized_keys and known_hosts"
    pushd ~#{USERNAME}/.ssh

    cat id_rsa.pub | xargs -I{} echo '^{}$' | xargs -I{} grep -v -e '{}' authorized_keys > cleaned_authorized_keys
    mv cleaned_authorized_keys authorized_keys
    cat id_rsa.pub >> authorized_keys
    chmod 0600 authorized_keys

    chown -R #{USERNAME}: ~#{USERNAME}
  SHELL

  config.vm.provision "exec_devtools_script", type: "shell",
    inline: "sudo -u #{USERNAME} -i bash ~#{USERNAME}/devtools.sh"

  config.vm.provision "setup_consul_example", type: "shell", inline: <<-SHELL
    sed -i -e 's/docker\./#{CONSUL_DOMAIN}./' ~#{USERNAME}/consul-registrator-setup/consul.json
  SHELL

  config.vm.provision "setup_nfs_export", type: "shell", inline: <<-SHELL
    echo "*** Installing nfs-kernel-server"
    apt-get install -y -qq nfs-kernel-server
    service nfs-kernel-server restart

    [[ ! -d ~#{USERNAME}/#{NFS_MOUNT_DIRNAME} ]] && mkdir ~#{USERNAME}/#{NFS_MOUNT_DIRNAME}
    echo "File from #{VM_NAME}" > ~#{USERNAME}/#{NFS_MOUNT_DIRNAME}/README.txt
    chown -R #{USERNAME}: ~#{USERNAME}

    sed -i "/^\\/home\\/#{USERNAME}\\/#{NFS_MOUNT_DIRNAME} /d" /etc/exports
    echo "/home/#{USERNAME}/#{NFS_MOUNT_DIRNAME} #{VM_GATEWAY_IP}(rw,sync,no_subtree_check,insecure,anonuid=$(id -u #{USERNAME}),anongid=$(id -g #{USERNAME}),all_squash)" >> /etc/exports
    exportfs -a
  SHELL

  # Cleanup scripts
  config.vm.provision "shell", name: "cleanup", inline: <<-SHELL
    echo "** Cleaning up old packaged with 'apt autoremove' ... "
    apt-get autoremove -y
  SHELL

  if ENABLE_GUI
    config.vm.provision "file", source: "./enable_gui.sh", destination: "/tmp/enable_gui.sh"
    config.vm.provision "shell", name: "enable_gui", inline: <<-SHELL
      mv /tmp/enable_gui.sh ~#{USERNAME}/
      sudo -u #{USERNAME} -i bash enable_gui.sh
    SHELL
  end

  config.trigger.after [:up] do |t|
    t.name = "Docker Usage"
    t.info = "** Run 'export DOCKER_HOST=\"tcp://#{VM_IP}:2375\"' on host to interact with docker in the vagrant guest.\n" +
             "** See https://docs.docker.com/engine/reference/commandline/cli/#environment-variables"
  end

  config.trigger.after [:up] do |t|
    t.name = "Host2Guest Routing"
    t.info = "** Setting up routing to .#{CONSUL_DOMAIN} domain"
    t.run = { path: "./setup_routes" }
  end

  config.trigger.after [:up] do |t|
    t.name = "Guest2Host NFS Export & mount"
    t.info = "** Mouting NFS share"
    t.run = { path: "./mount_nfs_share" }
  end

  config.trigger.after [:up] do |t|
    t.name = "Host2Guest Diff Check"
    t.info = "** Starting diff check for local backup and guest.\n"
    t.run = {
      inline: "rsync -nav #{VM_IP}:#{NFS_MOUNT_DIRNAME}/ #{File.expand_path(LOCAL_NFS_SYNC_DIR)}"
    }
  end

  config.trigger.before [:halt] do |t|
    t.name = "Guest2Host Sync"
    t.info = "** Starting synchronization from GUEST to HOST.\n"
    t.run = {
      inline: "rsync -av --delete #{VM_IP}:#{NFS_MOUNT_DIRNAME}/ #{File.expand_path(LOCAL_NFS_SYNC_DIR)}"
    }
  end
end
