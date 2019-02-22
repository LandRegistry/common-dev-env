require_relative 'utilities'

def provision_alembic96(root_loc)
  puts colorize_lightblue('Searching for alembic code (Postgres 9.6)')
  require 'yaml'
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

  started = false
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for alembic code
    # if the app specifically specifies postgres in it's commodity list
    unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
      puts colorize_red("No configuration.yml found for #{appname}")
      next
    end
    next unless commodity_required?(root_loc, appname, 'postgres-9.6')
    next unless File.exist?("#{root_loc}/apps/#{appname}/manage.py")

    unless started
      start_postgres_for_alembic
      started = true
    end
    puts colorize_pink("Found some in #{appname}")
    run_command('docker-compose run --rm ' + appname + ' bash -c "cd /src && export SQL_USE_ALEMBIC_USER=yes && ' \
                'export SQL_PASSWORD=superroot && python3 manage.py db upgrade"')
  end
end

def start_postgres_for_alembic
  run_command_noshell(['docker-compose', 'up', '-d', 'postgres-96'])
  # Better not run anything until postgres is ready to accept connections...
  puts colorize_lightblue('Waiting for Postgres 9.6 to finish initialising')

  while run_command_noshell(['docker', 'exec', 'postgres-96', 'pg_isready', '-h', 'localhost']) != 0
    puts colorize_yellow('Postgres 9.6 is unavailable - sleeping')
    sleep(1)
  end

  # Sleep 3 more seconds to allow the root user to be set up if needed
  sleep(3)

  puts colorize_green('Postgres 9.6 is ready')
end
