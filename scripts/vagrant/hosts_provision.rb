require 'yaml'
# Public: Provision the host's hosts file.
#
# root_loc - The root location of the development environment.
#
def provision_hosts(root_loc)
  puts colorize_lightblue('Searching for host file updates')

  host_additions = [] # Holds a list of hosts file entries

  return unless File.exist?("#{root_loc}/common-dev-env/dev-env-config/configuration.yml")

  # Determine new host details
  config = YAML.load_file("#{root_loc}/common-dev-env/dev-env-config/configuration.yml")
  if config['applications']
    config['applications'].each do |appname, _appconfig|
      next unless File.exist?("#{root_loc}/common-dev-env/apps/#{appname}/fragments/host-fragments.yml")

      puts colorize_pink("Found a Hosts provision for #{appname}")
      # Allow each app to ammend more than one line to the file.
      hosts = YAML.load_file("#{root_loc}/common-dev-env/apps/#{appname}/fragments/host-fragments.yml")
      hosts['hosts'].each do |entry|
        unless host_additions.include? entry
          # Must be in the form <IP Address><Space><Domain Name> e.g "127.0.0.1 ThisGoesToLocalHost"
          host_additions.push(entry)
        end
      end
    end
  end

  return if host_additions.empty?

  # Now modify the host's file according to OS
  add_hosts_to_file(host_additions)
end

def add_hosts_to_file(host_additions)
  puts colorize_lightblue("Additions: #{host_additions}")
  hosts_file = if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
                 # LINUX or MAC OS (NOT TESTED)
                 '/etc/hosts'
               else
                 # WINDOWS
                 'C:/Windows/System32/drivers/etc/hosts'
               end

  file = File.read(hosts_file)
  host_additions.each do |s|
    if file.include? s
      puts colorize_yellow("Host already has entry: #{s}")
    else
      File.write(hosts_file, "\n" + s, mode: 'a')
    end
  end
end
