require_relative 'utilities'
require 'yaml'

def provision_postgres96(root_loc)
  puts colorize_lightblue('Searching for Postgres 9.6 initialisation SQL in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  started = false
  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies postgres in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'postgres-9.6')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/postgres-init-fragment.sql")
      started = start_postgres96_maybe(root_loc, appname, started)
    else
      puts colorize_yellow("#{appname} says it uses Postgres 9.6 but doesn't contain an init SQL file. " \
                           'Oh well, onwards we go!')
    end
  end
end

def start_postgres96_maybe(root_loc, appname, started)
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'postgres-9.6')
    puts colorize_yellow("Postgres 9.6 has previously been provisioned for #{appname}, skipping")
  else
    started = start_postgres96(root_loc, appname, started)
  end
  started
end

def start_postgres96(root_loc, appname, started)
  unless started
    run_command_noshell(['docker-compose', 'up', '-d', 'postgres-96'])
    # Better not run anything until postgres is ready to accept connections...
    puts colorize_lightblue('Waiting for Postgres 9.6 to finish initialising')

    command_output = []
    command_outcode = 1
    until command_outcode.zero? && command_output.any? && command_output[0].start_with?('"healthy"')
      command_output.clear
      command_outcode = run_command("docker inspect --format='{{json .State.Health.Status}}' postgres-96", command_output)
      puts colorize_yellow('Postgres 9.6 is unavailable - sleeping')
      sleep(3)
    end

    # Sleep 3 more seconds to allow the root user to be set up if needed
    sleep(3)

    puts colorize_green('Postgres 9.6 is ready')
    started = true
  end
  # Copy the app's init sql into postgres then execute it with psql.
  # We don't just use docker cp with a plain file path as the source, to deal with WSL,
  # where LinuxRuby passes a path to WindowsDocker that it can't parse.
  # Therefore we create and pipe a tar file into docker cp instead, handy as tar runs in the
  # shell and understands Ruby's paths in both WSL and Git Bash!
  run_command('tar -c ' \
              " -C #{root_loc}/apps/#{appname}/fragments" + # This is the context, so tar will not contain file path
              ' postgres-init-fragment.sql' + # The file to add to the tar
              ' | docker cp - postgres-96:/') # Pipe it into docker cp, which will extract it for us
  run_command_noshell(['docker', 'exec', 'postgres-96', 'psql', '-q', '-f', 'postgres-init-fragment.sql'])

  # Update the .commodities.yml to indicate that postgres has now been provisioned
  set_commodity_provision_status(root_loc, appname, 'postgres-9.6', true)
  started
end
