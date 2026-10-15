require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_floci(root_loc, new_containers)
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value
  new_container = false
  if new_containers.include?('floci')
    new_container = true
    puts colorize_yellow('The Floci container has been newly created - '\
                         'provision status in .commodities will be ignored')
  end

  floci_initialised = false

  config['applications'].each_key do |appname|
    # To help enforce the accuracy of the app's dependency file, only search for init script
    # if the app specifically specifies floci in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'floci')

    # Load any init fragments contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/floci-init-fragment.sh")
      process_floci_fragment(root_loc, appname, floci_initialised, new_container)
    end
  end
end

def process_floci_fragment(root_loc, appname, floci_initialised, new_container)
  result = floci_initialised
  puts colorize_pink("Found a Floci init fragment in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'floci') && !new_container
    puts colorize_yellow("Floci has previously been provisioned for #{appname}, skipping")
  else
    unless floci_initialised
      init_floci
      result = true
    end
    init_floci_sh(root_loc, appname)
  end
  result
end

def init_floci_sh(root_loc, appname)
  # See comments in provision_postgres.rb for why we are doing it this way
  run_command('tar -c' \
              " -C #{root_loc}/apps/#{appname}/fragments" \
              ' floci-init-fragment.sh' \
              ' | docker cp - floci:/')

  cmd = 'docker exec floci bash -c "sh /floci-init-fragment.sh"'
  exit_code = run_command(cmd)

  puts colorize_lightblue("Completed #{appname} Floci fragment")

  if ![0].include?(exit_code)
    # if exit_code != 0
    puts colorize_red("Something went wrong with the Floci setup. Exitcode - #{exit_code}")
  else
    puts colorize_yellow("Floci initialised correctly. Exitcode - #{exit_code}.")
    set_commodity_provision_status(root_loc, appname, 'floci', true)
  end
end

def init_floci
  # Start floci
  run_command("#{ENV['DC_CMD']} up -d floci")
  puts colorize_green('Floci is ready')
end
