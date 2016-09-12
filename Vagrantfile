# -*- mode: ruby -*-
# vi: set ft=ruby :

VM_IP = "192.168.90.10"
USERNAME = ENV.fetch('USER')
SHELL = ENV.fetch('SHELL')

require 'open3'
def syscall(log, cmd)
  print "#{log} ... "
  status = nil
  Open3.popen2e(cmd) do |input, output, thr|
    output.each {|line| puts line }
    status = thr.value
  end
  if status.success?
    puts "done"
  else
    exit(1)
  end
end

class SetupDockerRouting < Vagrant.plugin('2')
  name 'setup_docker_routing'

  class Action
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)

      syscall("** Setting up routing to .docker domain", <<-EOF
          echo "** Adding resolver directory"
          sudo mkdir -p /etc/resolver

          echo "** Adding *.docker resolver"
          sudo bash -c "echo nameserver #{VM_IP} > /etc/resolver/docker"

          echo "** Adding routes"
          sudo route -n delete 172.17.0.0/16 #{VM_IP}
          sudo route -n add 172.17.0.0/16 #{VM_IP}
          sudo route -n delete 172.17.0.1/32 #{VM_IP}
          sudo route -n add 172.17.0.1/32 #{VM_IP}

          echo "** Mounting ubuntu NFS /home/#{USERNAME}/projects to ~/vagrant_projects"
          [ ! -f #{ENV.fetch('HOME')}/vagrant_projects ] && mkdir #{ENV.fetch('HOME')}/vagrant_projects
          sudo mount -t nfs -o rw #{VM_IP}:/home/#{USERNAME}/projects #{ENV.fetch('HOME')}/vagrant_projects
        EOF
      )
    end
  end

  action_hook(:setup_docker_routing, :machine_action_up) do |hook|
    hook.prepend(SetupDockerRouting::Action)
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: VM_IP

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "dev-on-ub"
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 2
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true
  end

  config.vm.provision "shell", inline: <<-SHELL
    update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"
    apt-get update -y

    apt-get install -y git vim curl sqlite network-manager nfs-kernel-server debconf-utils

    apt-get install -y apt-transport-https ca-certificates
    echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    apt-get purge lxc-docker
    apt-get update -y
    apt-cache policy docker-engine
    apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
    apt-get install -y docker-engine

    curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "creating docker group and user"
    groupadd -f docker
    usermod -aG docker $USER

    echo 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' >> /etc/default/grub
    service docker start

    echo "** Adding ubuntu user to admin group"
    groupadd -f admin
    usermod -aG admin $USER
  SHELL

  [
    { s: "~#{USERNAME}/.ssh/id_rsa", d: "/tmp/id_rsa" },
    { s: "~#{USERNAME}/.ssh/id_rsa.pub", d: "/tmp/id_rsa.pub" },
    { s: "~#{USERNAME}/.ssh/config", d: "/tmp/ssh_config" },
    { s: "./extras.sh", d: "/tmp/extras.sh" },
    { s: "./localextras.sh", d: "/tmp/localextras.sh" },
    { s: "./consul-registrator-setup/consul.json", d: "/tmp/consul.json" },
    { s: "./consul-registrator-setup/docker-compose.yml", d: "/tmp/docker-compose.yml" },
  ].each do |x|
    config.vm.provision "file", source: x[:s], destination: x[:d]
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get install -y zsh
    adduser --force-badname --shell=/bin/$(basename #{SHELL}) --disabled-password --gecos "#{USERNAME}" #{USERNAME}
    usermod -G docker,admin,sudo #{USERNAME}
    echo "#{USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/#{USERNAME}
    mkdir ~#{USERNAME}/.ssh
    chmod 0700 ~#{USERNAME}/.ssh
    mv /tmp/id_rsa* /tmp/ssh_config ~#{USERNAME}/.ssh/
    mv /tmp/extras.sh /tmp/localextras.sh ~#{USERNAME}/
    mkdir ~#{USERNAME}/projects
    echo "File from dev-on-ub" > ~#{USERNAME}/projects/README.txt

    mkdir ~#{USERNAME}/consul-registrator-setup/
    mv /tmp/consul.json /tmp/docker-compose.yml ~#{USERNAME}/consul-registrator-setup/

    chown -R #{USERNAME}: ~#{USERNAME}

    echo "/home/#{USERNAME}/projects 192.168.90.1(rw,sync,no_subtree_check,insecure,anonuid=$(id -u #{USERNAME}),anongid=$(id -g #{USERNAME}),all_squash)" >> /etc/exports
    service nfs-kernel-server start
    exportfs -a

    sudo -u #{USERNAME} -i bash extras.sh
  SHELL
end

