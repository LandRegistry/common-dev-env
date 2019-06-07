# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'scripts/vagrant/expose_ports'
require_relative 'scripts/vagrant/hosts_provision'
require_relative 'scripts/vagrant/plugin_manager'
require_relative 'scripts/utilities'
require 'open3'

# Ensures stdout is never buffered
STDOUT.sync = true

# Where is this file located? (From Ruby's perspective)
root_loc = __dir__

using_triggers_plugin = false

# Check that we have the right plugins installed
if ['up', 'reload', 'destroy'].include? ARGV[0]
  # If plugins have been installed, rerun the original vagrant command and abandon this one
  no_missing, installed_plugins = check_plugins ["vagrant-vbguest"]
  if no_missing == false
    puts "Please rerun your command (vagrant #{ARGV.join(' ')})"
    exit 0
  end
  using_triggers_plugin = true if installed_plugins.include?("vagrant-triggers")
end

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_version = "1902.01"

  config.vm.post_up_message = colorize_green('All done, environment is ready for use. Now "vagrant ssh" and use the dev-env as normal, i.e. "source run.sh up". If setting up a brand new dev-env, you\'ll then need a further "vagrant reload" afterwards to ensure hosts file changes and exposed ports are propagated out.')

  # Forward ssh agent so tools running in dev-env (e.g. and in
  # particular git) can use keys from host.
  config.ssh.forward_agent = true

  if ['up', 'reload'].include?(ARGV[0])
    # Find the ports of the apps and commodities on the host and add port forwards for them
    create_port_forwards(root_loc, config)
  end

  # In the event of user requesting a vagrant destroy
  # Remove files that no longer apply as the docker containers are all gone
  if installed_plugins && using_triggers_plugin
    config.trigger.after [:destroy] do
      run "bash #{root_loc}/scripts/vagrant/delete_env_files.sh #{root_loc}"
    end
  else
    config.trigger.after [:destroy] do |trigger|
      trigger.run = { inline: "bash #{root_loc}/scripts/vagrant/delete_env_files.sh #{root_loc}" }
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
  # TODO make this work properly somehow
  if installed_plugins && using_triggers_plugin
    config.trigger.after [:up, :reload] do
      #provision_hosts(root_loc)
    end
  else
    config.trigger.after [:up, :reload] do |trigger|
      #provision_hosts(root_loc)
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
