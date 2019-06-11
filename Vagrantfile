# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'scripts/vagrant/expose_ports'
require_relative 'scripts/vagrant/delete_env_files'
require_relative 'scripts/vagrant/hosts_provision'
require_relative 'scripts/utilities'
require 'open3'

# Ensures stdout is never buffered
STDOUT.sync = true

# Where is this file located? (From Ruby's perspective)
root_loc = __dir__

required_plugins = ['vagrant-vbguest', 'vagrant-triggers']
# We only need the triggers plugin if we're running a version that does not support them
required_plugins = ['vagrant-vbguest'] if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new("2.1.0")

if Gem::Version.new(Vagrant::VERSION) < Gem::Version.new("2.1.3")
  needs_installs = false
  required_plugins.each do |plugin|
    if !Vagrant.has_plugin?(plugin)
      needs_installs = true
      puts colorise_red("Plugin '#{plugin}' not found. Please install it using 'vagrant plugin install #{plugin}'")
    end
  end
  if needs_installs
    exit 1
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_version = "1902.01"

  # Required plugins are easier to specify in 2.1.3+, and stay local to project
  if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new("2.1.3")
    config.vagrant.plugins = required_plugins
  end

  config.vm.post_up_message = colorize_green('All done, environment is ready for use. Now "vagrant ssh" and use the dev-env as normal, i.e. "source run.sh up/reload/halt/destroy" and all the other usual aliases. If setting up a brand new dev-env, you\'ll then need a further "vagrant reload" afterwards to ensure hosts file changes and exposed ports are propagated out.')

  # Forward ssh agent so tools running in dev-env (e.g. and in
  # particular git) can use keys from host.
  config.ssh.forward_agent = true

  if ['up', 'reload'].include?(ARGV[0])
    # Find the ports of the apps and commodities on the host and add port forwards for them
    create_port_forwards(root_loc, config)
  end

  # In the event of user requesting a vagrant destroy
  # Remove files that no longer apply as the docker containers are all gone
  if Vagrant.has_plugin?("vagrant-triggers")
    config.trigger.after [:destroy] do
      delete_files(root_loc)
    end
  else
    config.trigger.after [:destroy] do |trigger|
      trigger.ruby do |env, machine|
        delete_files(root_loc)
      end
    end
  end

  # Disable automatic box update checking
  config.vm.box_check_update = false

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Run script to configure environment
  config.vm.provision :shell, :inline => "source /vagrant/scripts/vagrant/provision-environment.sh"

  # Install latest git
  config.vm.provision :shell, :inline => "source /vagrant/scripts/vagrant/install-git.sh"

  # Install Ruby as the vagrant user (so it goes in the right .bash_profile)
  config.vm.provision :shell, privileged: false, :inline => "source /vagrant/scripts/vagrant/install-ruby.sh"

  # Install docker and docker-compose
  config.vm.provision :shell, :inline => "source /vagrant/scripts/vagrant/install-docker.sh"

  # Hosts File - need to alter it on the "true" host as the common-dev-env will have modified the vagrant box
  if Vagrant.has_plugin?("vagrant-triggers")
    config.trigger.after [:up, :reload] do
      provision_hosts(root_loc)
    end
  else
    config.trigger.after [:up, :reload] do |trigger|
      trigger.ruby do |env, machine|
        provision_hosts(root_loc)
      end
    end
  end

  config.vm.provider "virtualbox" do |vb|
    if ENV.has_key?('VM_MEMORY')
      vm_memory = ENV['VM_MEMORY'].to_i
    else
      vm_memory = 4096
    end
    if ENV.has_key?('VM_CPUS')
      vm_cpus = ENV['VM_CPUS'].to_i
    else
      vm_cpus = 4
    end
    # Set a random name to avoid a folder-already-exists error after a destroy/up (virtualbox often leaves the folder lying around)
    vb.name = "landregistry-development #{Time.now.to_f}"
    # Set the resources to be used by the VM
    vb.customize ['modifyvm', :id, '--memory', vm_memory]
    vb.customize ["modifyvm", :id, "--cpus", vm_cpus]
    # Various recommended tweaks
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    vb.customize ['modifyvm', :id, '--paravirtprovider', 'kvm']
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    # Ensure the time difference to host does not get too large
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-interval", 10000]
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust", 100]
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore", 1]
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000]
  end

end
