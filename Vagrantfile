# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'scripts/vagrant/expose_ports'
require_relative 'scripts/vagrant/hosts_provision'
require_relative 'scripts/delete_env_files'
require_relative 'scripts/utilities'
require 'open3'

# Ensures stdout is never buffered
STDOUT.sync = true

# Where is this file located? (From Ruby's perspective)
root_loc = __dir__

required_plugins = {'vagrant-vbguest' => {'version' => '> 0.21.0'}, 'vagrant-triggers' => {}}
# We only need the triggers plugin if we're running a version that does not support them (and the ruby block)
required_plugins = {'vagrant-vbguest' => {'version' => '> 0.21.0'}} if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('2.2.0')

if Gem::Version.new(Vagrant::VERSION) < Gem::Version.new('2.1.3')
  needs_installs = false
  required_plugins.each_key do |plugin|
    unless Vagrant.has_plugin?(plugin)
      needs_installs = true
      puts colorize_red("Plugin '#{plugin}' not found. Please install it using 'vagrant plugin install #{plugin}'")
    end
  end
  exit 1 if needs_installs
end

Vagrant.configure('2') do |config|
  config.vm.box = 'centos/8'
  config.vm.box_version = '1905.1'

  # Required plugins are easier to specify in 2.1.3+, and stay local to project
  config.vagrant.plugins = required_plugins if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('2.1.3')

  # Workaround for https://github.com/hashicorp/vagrant/issues/9442
  Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com') unless Vagrant::DEFAULT_SERVER_URL.frozen?

  config.vm.post_up_message = colorize_green('All done, environment is ready for use. Now "vagrant ssh" and use '\
                                             'the dev-env as normal, i.e. "source run.sh up/reload/halt/destroy" '\
                                             'and all the other usual aliases. If setting up a brand new dev-env, '\
                                             'you\'ll then need a further "vagrant reload" afterwards to ensure '\
                                             'hosts file changes and exposed ports are propagated out.')

  # Forward ssh agent so tools running in dev-env (e.g. and in
  # particular git) can use keys from host.
  config.ssh.forward_agent = true

  if %w[up reload].include?(ARGV[0])
    # Find the ports of the apps and commodities on the host and add port forwards for them
    create_port_forwards(root_loc, config)
  end

  if Vagrant.has_plugin?('vagrant-triggers')
    config.trigger.after [:up, :reload] do
      # Hosts File - need to alter it on the "true" host as the common-dev-env will have modified the vagrant box
      provision_hosts(root_loc)
    end
    config.trigger.after [:destroy] do
      # Remove files that no longer apply as the docker containers are all gone
      delete_files(root_loc)
    end
    config.trigger.before [:halt, :reload] do
      # Stop any running containers cleanly
      run_command('vagrant ssh -c "source run.sh halt"')
    end
  else
    config.trigger.after [:up, :reload] do |trigger|
      trigger.ruby do
        provision_hosts(root_loc)
      end
    end
    config.trigger.after [:destroy] do |trigger|
      trigger.ruby do
        delete_files(root_loc)
      end
    end
    config.trigger.before [:halt, :reload] do |trigger|
      trigger.ruby do
        run_command('vagrant ssh -c "source run.sh halt"')
      end
    end
  end

  # Disable automatic box update checking
  config.vm.box_check_update = false

  config.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

  # Run script to configure environment
  config.vm.provision 'shell', inline: 'source /vagrant/scripts/vagrant/provision-environment.sh'

  # Install latest git
  config.vm.provision 'shell', inline: 'source /vagrant/scripts/vagrant/install-git.sh'

  # Install Ruby
  config.vm.provision 'shell', inline: 'source /vagrant/scripts/vagrant/install-ruby.sh'

  # Install docker and docker-compose
  config.vm.provision 'shell', inline: 'source /vagrant/scripts/vagrant/install-docker.sh'

  config.vm.provider 'virtualbox' do |vb|
    vm_memory = ENV.key?('VM_MEMORY') ? ENV['VM_MEMORY'].to_i : 4096

    vm_cpus = ENV.key?('VM_CPUS') ? ENV['VM_CPUS'].to_i : 4

    # Set a random name to avoid a folder-already-exists error after a destroy/up
    # (virtualbox often leaves the folder lying around)
    vb.name = "common-dev-env #{Time.now.to_f}"
    # Set the resources to be used by the VM
    vb.customize ['modifyvm', :id, '--memory', vm_memory]
    vb.customize ['modifyvm', :id, '--cpus', vm_cpus]
    # Various recommended tweaks
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    vb.customize ['modifyvm', :id, '--paravirtprovider', 'kvm']
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize ['modifyvm', :id, '--chipset', 'ich9']
    # Ensure the time difference to host does not get too large
    vb.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-interval', 10_000]
    vb.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust', 100]
    vb.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore', 1]
    vb.customize ['guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold', 1_000]
  end
end
