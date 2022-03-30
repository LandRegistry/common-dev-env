require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_localstack(root_loc, new_containers)
  puts colorize_lightblue('Searching for Localstack initialisation script in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value
  new_db_container = false
  if new_containers.include?('localstack')
    new_db_container = true
    puts colorize_yellow('The Localstack container has been newly created - '\
                         'provision status in .commodities will be ignored')
  end

  localstack_initialised = false

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies localstack in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'localstack')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/localstack-init-fragment.sh")
      database_initialised = process_localstack_fragment(root_loc, appname, localstack_initialised, new_db_container)
    else
      puts colorize_yellow("#{appname} says it uses Localstack but doesn't contain an init file.
          Oh well, onwards we go!")
    end
  end
end

def process_localstack_fragment(root_loc, appname, localstack_initialised, new_db_container)
  result = localstack_initialised
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'localstack') && !new_db_container
    puts colorize_yellow("Localstack has previously been provisioned for #{appname}, skipping")
  else
    unless localstack_initialised
      init_localstack
      result = true
    end
    init_localstack_sh(root_loc, appname)
  end
  result
end

def init_localstack_sh(root_loc, appname)
  # See comments in provision_postgres.rb for why we are doing it this way
  run_command('tar -c' \
              " -C #{root_loc}/apps/#{appname}/fragments" \
              ' localstack-init-fragment.sh' \
              ' | docker cp - localstack:/')

  run_command('docker exec localstack bash -c "chmod o+rx /localstack-init-fragment.sh"')

  cmd = 'docker exec localstack bash -c "sh /localstack-init-fragment.sh"'
  exit_code = run_command(cmd)

  puts colorize_lightblue("Completed #{appname} Localstack fragment")

  if ![0].include?(exit_code)
    # if exit_code != 0
    puts colorize_red("Something went wrong with the Localstack setup. Exitcode - #{exit_code}")
  else
    puts colorize_yellow("Localstack initialised correctly. Exitcode - #{exit_code}.")
    set_commodity_provision_status(root_loc, appname, 'localstack', true)
  end
end

def init_localstack
  # Start Localstack
  run_command("#{ENV['DC_CMD']} up -d localstack")
  puts colorize_green('Localstack is ready')
end
