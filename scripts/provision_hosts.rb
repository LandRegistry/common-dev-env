require_relative 'utilities'
require 'yaml'

# Public: Provision the host's hosts file.
#
# root_loc - The root location of the development environment.
#
def provision_hosts(root_loc)
  puts colorize_lightblue('Searching for host file updates')
  host_additions = get_host_additions(root_loc)

  # Now modify the host's file according to OS
  return if host_additions.empty?

  puts colorize_lightblue("Additions: #{host_additions}")

  file = File.read(hosts_filename)
  host_additions.each do |s|
    if file.include? s
      puts colorize_yellow("Host already has entry: #{s}")
    else
      File.write(hosts_filename, "\n" + s, mode: 'a')
    end
  end
end

def hosts_filename
  wsl_version_filename = "/proc/version"
  if !(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
    # WINDOWS
    'C:/Windows/System32/drivers/etc/hosts'
  elsif File.file?(wsl_version_filename) && File.foreach(wsl_version_filename).any?{ |l| l['microsoft'] }
    # assume on Linux via WSL
    '/mnt/c/Windows/System32/drivers/etc/hosts'
  else
    # Linux or Mac
		'/etc/hosts'
  end
end

def get_host_additions(root_loc)
  host_additions = [] # Holds a list of hosts file entries

  # Determine new host details
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # Check adfs is required
    next unless File.exist?("#{root_loc}/apps/#{appname}/fragments/host-fragments.yml")

    puts colorize_pink("Found a Hosts provision for #{appname}")
    # Allow each app to ammend more than one line to the file.
    hosts = YAML.load_file("#{root_loc}/apps/#{appname}/fragments/host-fragments.yml")
    hosts['hosts'].each do |entry|
      unless host_additions.include? entry
        # Must be in the form <IP Address><Space><Domain Name> e.g "127.0.0.1 ThisGoesToLocalHost"
        host_additions.push(entry)
      end
    end
  end
  host_additions
end
