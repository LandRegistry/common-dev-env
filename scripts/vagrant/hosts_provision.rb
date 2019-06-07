# Public: Provision the host's hosts file.
#
# root_loc - The root location of the development environment.
#
def provision_hosts(root_loc)
    puts colorize_lightblue("Searching for host file updates")
    require 'yaml'
    host_additions = [] # Holds a list of hosts file entries

    return unless File.exists?("#{root_loc}/common-dev-env/dev-env-config/configuration.yml")

    # Determine new host details
    config = YAML.load_file("#{root_loc}/common-dev-env/dev-env-config/configuration.yml")
    if config["applications"]
        config["applications"].each do |appname, appconfig|
            next unless File.exists?("#{root_loc}/common-dev-env/apps/#{appname}/fragments/host-fragments.yml")

            puts colorize_pink("Found a Hosts provision for #{appname}")
            # Allow each app to ammend more than one line to the file.
            hosts = YAML.load_file("#{root_loc}/common-dev-env/apps/#{appname}/fragments/host-fragments.yml")
            hosts["hosts"].each do |entry|
                unless host_additions.include? entry
                    host_additions.push(entry)  # Must be in the form <IP Address><Space><Domain Name> e.g "127.0.0.1 ThisGoesToLocalHost"
                end
            end
        end
    end


    # Now modify the host's file according to OS
    hosts_file = nil
    if !host_additions.empty?
        puts colorize_lightblue("Additions: #{host_additions}")
        if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
            # WINDOWS
            hosts_file = "C:/Windows/System32/drivers/etc/hosts"
        else
            # LINUX or MAC OS (NOT TESTED)
            hosts_file = "/etc/hosts"
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
end
