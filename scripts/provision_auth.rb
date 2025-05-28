require_relative 'utilities'
require 'yaml'

def provision_auth(root_loc, new_containers)
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value

  started = false
  config['applications'].each_key do |appname|
    # To help enforce the accuracy of the app's dependency file, only search for a conf file
    # if the app specifically specifies auth in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'auth')

    if commodity_provisioned?(root_loc, appname, 'auth') && !fresh_start(new_containers)
      puts colorize_yellow("LDIF files have already been loaded for #{appname}, skipping")
    else
      started = build_auth(root_loc, appname, started)

      # Update the .commodities.yml to indicate that auth has now been provisioned
      set_commodity_provision_status(root_loc, appname, 'auth', true)
    end
  end
end

def fresh_start(new_containers)
  return false unless new_containers.include?('openldap')

  puts colorize_yellow('The OpenLDAP container has been newly created - '\
      'provision status in .commodities will be ignored')
  true
end

def build_auth(root_loc, appname, already_started)
  # Load any LDIF files contained in the apps into the docker commands list
  started = already_started
  Dir.glob("#{root_loc}/apps/#{appname}/fragments/*.ldif").each do |file|
    puts colorize_pink("Found #{File.basename(file)} in #{appname}")
    unless started
      run_command("#{ENV['DC_CMD']} up -d --build --no-deps openldap")
      # Ensure connections are possible before loading any fragments
      sleep(5)
      started = true
    end
    run_command("docker exec -i openldap ldapadd -D cn=admin,dc=dev,dc=domain -w admin < #{file}")
  end
  started
end
