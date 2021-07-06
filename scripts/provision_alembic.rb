require_relative 'utilities'

def provision_alembic(root_loc)
  puts colorize_lightblue('Searching for alembic code')
  require 'yaml'
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

  started = false
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for alembic code
    # if the app specifically specifies postgres in it's commodity list
    # and they aren't suppressing it by setting perform_alembic_migration to false
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'postgres')
    next unless File.exist?("#{root_loc}/apps/#{appname}/manage.py")
    next unless migration_enabled?(root_loc, appname)

    unless started
      start_postgres_for_alembic
      started = true
    end
    puts colorize_pink("Found some in #{appname}")
    run_command("#{ENV['DC_CMD']} run --rm #{appname}" \
                ' bash -c "cd /src && export SQL_USE_ALEMBIC_USER=yes && ' \
                'export SQL_PASSWORD=superroot && python3 manage.py db upgrade"')
  end
end

def migration_enabled?(root_loc, appname)
  app_configuration = YAML.load_file("#{root_loc}/apps/#{appname}/configuration.yml")
  do_migration = app_configuration.fetch('perform_alembic_migration', true)
  puts colorize_yellow("Dev-env-triggered Alembic migration disabled for #{appname}, skipping") if do_migration == false
  do_migration
end

def start_postgres_for_alembic
  run_command_noshell(ENV['DC_CMD'].split(' ') + ['up', '-d', 'postgres'])
  # Better not run anything until postgres is ready to accept connections...
  puts colorize_lightblue('Waiting for Postgres to finish initialising')

  while run_command_noshell(['docker', 'exec', 'postgres', 'pg_isready', '-h', 'localhost']) != 0
    puts colorize_yellow('Postgres is unavailable - sleeping')
    sleep(1)
  end

  # Sleep 3 more seconds to allow the root user to be set up if needed
  sleep(3)

  puts colorize_green('Postgres is ready')
end
