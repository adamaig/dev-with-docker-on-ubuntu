# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.90.10"

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
    vb.name = "dev-on-ub2"
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 2
    # Display the VirtualBox GUI when booting the machine
    #vb.gui = true
  end

  USERNAME = ENV.fetch('USER')

  config.vm.provision "shell", inline: <<-SHELL
    update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"
    apt-get update -y
    apt-get install -y vim curl apt-transport-https ca-certificates sqlite network-manager
    echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    apt-get purge lxc-docker
    apt-get update -y
    apt-cache policy docker-engine
    apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
    apt-get install -y docker-engine docker-compose

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
    { s: "./extras.sh", d: "/tmp/extras.sh" },
  ].each do |x|
    config.vm.provision "file", source: x[:s], destination: x[:d]
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get install -y zsh
    adduser --force-badname --shell=/bin/zsh --disabled-password --gecos "#{USERNAME}" #{USERNAME}
    usermod -G docker,admin,sudo #{USERNAME}
    echo "#{USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/#{USERNAME}
    mkdir ~#{USERNAME}/.ssh 
    chmod 0700 ~#{USERNAME}/.ssh 
    mv /tmp/id_rsa* ~#{USERNAME}/.ssh/
    mv /tmp/extras.sh ~#{USERNAME}/
    chown -R #{USERNAME}: ~#{USERNAME}
    sudo -u #{USERNAME} -i bash extras.sh
  SHELL

end

