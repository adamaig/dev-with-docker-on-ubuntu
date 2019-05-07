# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
require 'erb'
require 'pp'

# Default configuration options
config_options = {
  "user" => {"username" => ENV.fetch('USER'), "shell" => ENV.fetch('SHELL')},
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
  "docker" => {"bridge_ip" => "172.17.0.1", "subnet_ip" => "172.17.0.0", "subnet_mask" => 16},
  "consul" => {"dns_port" => 8600, "domain" => "docker"},
  "nfs" => {
    "mount_on_up" => true,
    "directory_name" => "vagrant_projects",
    "host_mount_options" => "rw,bg,hard,nolocks,intr,sync"
  }
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
  #config_options.merge!()
  config_options = config_options.options_merge(config_yaml)
  puts "** Running with options:"
  pp config_options
end

# Specifies the docker-engine apt package version
DOCKER_ENGINE_VERSION="5:18.09.5~3-0~ubuntu-xenial"
# Specifies the docker-compose release version
DOCKER_COMPOSE_VERSION="1.24.0"

# Set this to true in order to enable the gui and install necessary packages
ENABLE_GUI = config_options["enable_gui"]

# VM_NAME specifies the box name that will appear in virtualbox.
VM_NAME = config_options["vm"]["name"]

# VM_IP specifies the port the VM will run on, and the routes
VM_IP = config_options["vm"]["ip"]

# VM_GATEWAY_IP specifies the NFS export access. Corresponds to the host's IP
# in the vboxnet
VM_GATEWAY_IP = config_options["vm"]["gateway_ip"]

# Used to config_optionsure the docker-engine bridge network and OSX routes
DOCKER_BRIDGE_IP = config_options["docker"]["bridge_ip"]
DOCKER_SUBNET_IP = config_options["docker"]["subnet_ip"]
DOCKER_SUBNET_MASK = config_options["docker"]["subnet_mask"]

# Specifies the OSX route to the docker subnet
DOCKER_SUBNET_CIDR = "#{DOCKER_SUBNET_IP}/#{DOCKER_SUBNET_MASK}"
# Used to specify subet used by the docker engine bridge network
DOCKER_BRIDGE_CIDR = "#{DOCKER_BRIDGE_IP}/#{DOCKER_SUBNET_MASK}"

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

# This var will be used to configure the user created in the vagrant, and
# should match the user running the vagrant box
USERNAME = config_options["user"]["username"]
SHELL = config_options["user"]["shell"]

# The timezone for the box
TIMEZONE = config_options["tz"]

# These HEREDOCs are additional config files used to setup the docker development
# environment and dns lookups
dnsmasq_base_conf = <<EOF
listen-address=127.0.0.1
listen-address=#{DOCKER_BRIDGE_IP}
listen-address=#{VM_IP}
server=/.service.#{CONSUL_DOMAIN}/127.0.0.1##{CONSUL_DNS_PORT}
EOF


dnsmasq_docker_conf = <<EOF
listen-address=#{DOCKER_BRIDGE_IP}
server=/.service.#{CONSUL_DOMAIN}/127.0.0.1##{CONSUL_DNS_PORT}
EOF

# The systemd dropin config for the docker service
docker_drop_in_conf = <<EOF
[Unit]
Before=dnsmasq.service

[Service]
# Reset the ExecStart values due to systemd quirk
ExecStart=
# Manage configuration options in /etc/docker/daemon.json
ExecStart=/usr/bin/dockerd
# Ensure traffic to containers is not dropped
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
# iptables -I DOCKER-USER -i ext_if ! -s #{VM_IP} -j DROP
EOF

docker_daemon_json = <<EOF
{
  "hosts": ["fd://", "tcp://0.0.0.0:2375"],
  "bip": "#{DOCKER_BRIDGE_CIDR}"
}
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

require "open3"
class SetupDockerRouting < Vagrant.plugin("2")
  name "setup_docker_routing"

  class Action
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)

      if NFS_MOUNT_ON_UP
        syscall("** Mouting NFS share", <<-EOF
            ./mount_nfs_share
          EOF
        )
      end
      syscall("** Setting up routing to .#{CONSUL_DOMAIN} domain", <<-EOF
          ./setup_routes
        EOF
      )
    end

    def syscall(log, cmd)
      print "#{log} ... "
      status = nil
      Open3.popen2e(cmd) do |input, output, thr|
        output.each { |line| puts line }
        status = thr.value
      end
      if status.success?
        puts "done"
      else
        exit(1)
      end
    end
  end

  action_hook(:setup_docker_routing, :machine_action_up) do |hook|
    hook.prepend(SetupDockerRouting::Action)
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_check_update = true

  # Make sure you have XQuartz running on the host
  config.ssh.forward_x11 = true

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: VM_IP

  config.vm.provider "virtualbox" do |vb|
    vb.name = VM_NAME
    vb.memory = config_options["vm"]["memory"]
    vb.cpus = config_options["vm"]["cpus"]
    if ENABLE_GUI
      vb.gui = ENABLE_GUI
      vb.customize ["modifyvm", :id, "--vram", config_options["vm"]["vram"]]
      vb.customize ["modifyvm", :id, "--accelerate3d", config_options["vm"]["accelerate_3d"]]
      vb.customize ["modifyvm", :id, "--clipboard", config_options["vm"]["clipboard"]]
      vb.customize ["modifyvm", :id, "--draganddrop", config_options["vm"]["draganddrop"]]
    end
  end

  config.vm.provision "shell", name: "base_setup", inline: <<-SHELL
    update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" \
      LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" \
      LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"

    echo "*** Updating apt index"
    apt-get update -y
    apt-get install -y --no-install-recommends \
      debconf-utils apt-transport-https ca-certificates software-properties-common

    echo "*** Installing base services: ntp, dnsmasq, nfs-kernel-server, network-manager"
    apt-get install -y ntp network-manager dnsmasq nfs-kernel-server

    echo "*** Installing tools: curl, wget, git, vim, sqlite"
    apt-get install -y curl wget git vim sqlite

    echo "** Configuring timezone"
    timedatectl set-timezone #{TIMEZONE}

    echo "** Modifying NetworkManager and dnsmasq to support routing to localhost"
    sed -e 's/.*bind-interfaces/# bind-interfaces/' -i /etc/dnsmasq.d/network-manager
    sed -e 's/.*dns=dnsmasq/# dns=dnsmasq/' -i /etc/NetworkManager/NetworkManager.conf
    echo "#{dnsmasq_base_conf}" > /etc/dnsmasq.d/10-base-dns

    echo "Reloading systemclt configs and restarting services"
    systemctl daemon-reload
    service ntp restart
    service nfs-kernel-server restart
    service network-manager restart
    service dnsmasq restart
  SHELL

  config.vm.provision "shell", name: "docker_setup", inline: <<-SHELL
    echo "*** Running setup from docker installation"
    # Remove any prior docker versions
    apt-get remove docker docker-engine docker.io
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    echo "*** Updating apt index"
    apt-get update -y

    echo "*** Installing Docker CE"
    apt-get install -y docker-ce=#{DOCKER_ENGINE_VERSION} \
      docker-ce-cli=#{DOCKER_ENGINE_VERSION} \
      containerd.io

    echo "** Checking if docker-compose installation is #{DOCKER_COMPOSE_VERSION}"
    if [[ (! -f /usr/local/bin/docker-compose) || (! `docker-compose --version` =~ "#{DOCKER_COMPOSE_VERSION}") ]]
    then
      url_base="https://github.com/docker/compose/releases/download/"
      version="#{DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`"
      curl -s -L $url_base$version -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
    fi

    sed -i "/^GRUB_CMDLINE_LINUX/d" /etc/default/grub
    echo 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' >> /etc/default/grub
    update-grub

    echo "** Modifying NetworkManager and dnsmasq to support routing to service.docker"
    sed -e 's/.*bind-interfaces/# bind-interfaces/' -i /etc/dnsmasq.d/network-manager
    sed -e 's/.*dns=dnsmasq/# dns=dnsmasq/' -i /etc/NetworkManager/NetworkManager.conf
    echo "#{dnsmasq_docker_conf}" > /etc/dnsmasq.d/11-docker

    echo "** Adding /etc/docker/daemon.json configuration"
    echo '#{docker_daemon_json}' >> /etc/docker/daemon.json

    echo "** Setting up systemd drop-in config for docker daemon"
    [ ! -d /etc/systemd/system/docker.service.d ] && mkdir /etc/systemd/system/docker.service.d
    echo "#{docker_drop_in_conf}" > /etc/systemd/system/docker.service.d/dev-on-docker.conf

    echo "Reloading systemclt configs and restarting services"
    systemctl daemon-reload
    service dnsmasq restart
    service docker restart

    echo "creating admin and docker groups, adding vagrant user"
    groupadd -f docker
    groupadd -f admin
    usermod -aG admin,docker vagrant
  SHELL

  config.vm.provision "shell", name: "kube_setup", inline: <<~SHELL
    snap install microk8s --classic
  SHELL

  [
    { s: "~#{USERNAME}/.ssh/id_rsa", d: "/tmp/id_rsa" },
    { s: "~#{USERNAME}/.ssh/id_rsa.pub", d: "/tmp/id_rsa.pub" },
    { s: "~#{USERNAME}/.ssh/config", d: "/tmp/ssh_config" },
    { s: "./extras.sh", d: "/tmp/extras.sh" },
    { s: "./localextras.sh", d: "/tmp/localextras.sh" },
    { s: "./consul-registrator-setup/consul.json", d: "/tmp/consul.json" },
    { s: "./consul-registrator-setup/docker-compose.yml", d: "/tmp/docker-compose.yml" }
  ].each do |x|
    config.vm.provision "file", source: x[:s], destination: x[:d]
  end

  # User creation scripts
  config.vm.provision "shell", name: "create_user", inline: <<-SHELL
    apt-get install -y $(basename #{SHELL})
    [[ -z "$(getent passwd #{USERNAME})" ]] && adduser --force-badname --uid 9999 --shell=/bin/$(basename #{SHELL}) --disabled-password --gecos "#{USERNAME}" #{USERNAME}
    usermod -G docker,admin,sudo,staff #{USERNAME}
    echo "#{USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/#{USERNAME}

    echo "** Setting up ssh keys and hosts"
    [[ ! -d ~#{USERNAME}/.ssh ]] && mkdir ~#{USERNAME}/.ssh
    chmod 0700 ~#{USERNAME}/.ssh
    mv /tmp/id_rsa* ~#{USERNAME}/.ssh/
    mv /tmp/ssh_config ~#{USERNAME}/.ssh/config

    echo "** Cleaning up ssh authorized_keys and known_hosts"
    cat ~#{USERNAME}/.ssh/id_rsa.pub | xargs -I{} echo '^{}$' | xargs -I{} grep -v -e '{}' ~#{USERNAME}/.ssh/authorized_keys > ~#{USERNAME}/.ssh/cleaned_authorized_keys
    mv ~#{USERNAME}/.ssh/cleaned_authorized_keys ~#{USERNAME}/.ssh/authorized_keys
    cat ~#{USERNAME}/.ssh/id_rsa.pub >> ~#{USERNAME}/.ssh/authorized_keys
    chmod 0600 ~#{USERNAME}/.ssh/authorized_keys
    sudo -u #{USERNAME} -i ssh-keygen -R github.com
    sudo -u #{USERNAME} -i ssh-keygen -R bitbucket.org
    ssh-keyscan -H github.com bitbucket.org >> ~#{USERNAME}/.ssh/known_hosts

    mv /tmp/extras.sh /tmp/localextras.sh ~#{USERNAME}/
    [[ ! -d ~#{USERNAME}/#{NFS_MOUNT_DIRNAME} ]] && mkdir ~#{USERNAME}/#{NFS_MOUNT_DIRNAME}
    echo "File from #{VM_NAME}" > ~#{USERNAME}/#{NFS_MOUNT_DIRNAME}/README.txt

    [[ ! -d ~#{USERNAME}/consul-registrator-setup ]] && mkdir ~#{USERNAME}/consul-registrator-setup/
    mv /tmp/consul.json /tmp/docker-compose.yml ~#{USERNAME}/consul-registrator-setup/
    sed -i -e 's/docker\./#{CONSUL_DOMAIN}./' ~#{USERNAME}/consul-registrator-setup/consul.json

    chown -R #{USERNAME}: ~#{USERNAME}

    sed -i "/^\\/home\\/#{USERNAME}\\/#{NFS_MOUNT_DIRNAME} /d" /etc/exports
    echo "/home/#{USERNAME}/#{NFS_MOUNT_DIRNAME} #{VM_GATEWAY_IP}(rw,sync,no_subtree_check,insecure,anonuid=$(id -u #{USERNAME}),anongid=$(id -g #{USERNAME}),all_squash)" >> /etc/exports
    exportfs -a

    sudo -u #{USERNAME} -i bash extras.sh
  SHELL

  # Cleanup scripts
  config.vm.provision "shell", name: "cleanup", inline: <<-SHELL
    echo "** Cleaning up old packaged with 'apt autoremove' ... "
    apt-get autoremove -y

    echo "** Linking /Users -> /home in the guest. Supports volume mounting in docker-compose path expansion over the DOCKER_HOST tcp connection."
    [[ ! -L /Users ]] && ln -s /home /Users

    echo "** Run 'export DOCKER_HOST="tcp://#{VM_IP}:2375"' on this host to interact with docker in the vagrant guest"
  SHELL

  if ENABLE_GUI
    config.vm.provision "file", source: "./enable_gui.sh", destination: "/tmp/enable_gui.sh"
    config.vm.provision "shell", name: "enable_gui", inline: <<-SHELL
      mv /tmp/enable_gui.sh ~#{USERNAME}/
      sudo -u #{USERNAME} -i bash enable_gui.sh
    SHELL
  end
end
