require_relative 'utilities'
require 'yaml'

def provision_wiremock(root_loc, new_containers)
  puts colorize_lightblue('Searching for Wiremock json files in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value
  new_container = false
  if new_containers.include?('wiremock')
    new_container = true
    puts colorize_yellow('The Wiremock container has been newly created - '\
                         'provision status in .commodities will be ignored')
  end

  started = false
  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for a conf file
    # if the app specifically specifies wiremock in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'wiremock')

    started = build_wiremock(root_loc, appname, started, new_container)
  end

  # Will need to let it start again to pick up the newly copied files
  run_command("#{ENV['DC_CMD']} stop wiremock") if started
end

def build_wiremock(root_loc, appname, already_started, new_container)
  # Load any mapping files contained in the apps into the docker commands list
  started = already_started
  if File.exist?("#{root_loc}/apps/#{appname}/fragments/wiremock-fragment.json")
    puts colorize_pink("Found some in #{appname}")
    if commodity_provisioned?(root_loc, appname, 'wiremock') && !new_container
      puts colorize_yellow("Wiremock has previously been provisioned for #{appname}, skipping")
    else
      unless started
        run_command("#{ENV['DC_CMD']} up -d --no-deps wiremock")
        started = true
      end
      # See comments in provision_postgres.rb for why we are doing it this way
      run_command('tar -c' \
                  " -C #{root_loc}/apps/#{appname}/fragments" \
                  ' wiremock-fragment.json' \
                  ' | docker cp - wiremock:/wiremock/mappings/')

      # Rename the file so it is unique and wont get overwritten by any others we copy up
      # Also, GitBash needs the inner quotes to be doubles
      run_command('docker exec wiremock bash -c "' \
        "mv /wiremock/mappings/wiremock-fragment.json /wiremock/mappings/#{appname}-wiremock-fragment.json" \
        '"')

      # Update the .commodities.yml to indicate that Wiremock has now been provisioned
      set_commodity_provision_status(root_loc, appname, 'wiremock', true)
    end
  end
  started
end
