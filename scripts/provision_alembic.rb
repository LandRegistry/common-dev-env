require_relative 'utilities'
require_relative 'provision_postgres'

def provision_alembic(root_loc, postgres_version)
  container = postgres_container(postgres_version)
  return if container == ''

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
    next unless proceed_with_migration?(root_loc, appname, container)

    unless started
      start_postgres_for_alembic(postgres_version)
      started = true
    end
    puts colorize_pink("Found some in #{appname}")
    run_command("#{ENV['DC_CMD']} run --rm #{appname}" \
                ' bash -c "cd /src && export SQL_USE_ALEMBIC_USER=yes && ' \
                'export SQL_PASSWORD=superroot && python3 manage.py db upgrade"')
  end
end

def proceed_with_migration?(root_loc, appname, container)
  File.exist?("#{root_loc}/apps/#{appname}/configuration.yml") &&
    commodity_required?(root_loc, appname, container_to_commodity(container)) &&
    File.exist?("#{root_loc}/apps/#{appname}/manage.py") &&
    migration_enabled?(root_loc, appname)
end

def migration_enabled?(root_loc, appname)
  app_configuration = YAML.load_file("#{root_loc}/apps/#{appname}/configuration.yml")
  do_migration = app_configuration.fetch('perform_alembic_migration', false)
  print_migration_enabled_warning(appname) if do_migration == true
  do_migration
end

def print_migration_enabled_warning(appname)
  puts colorize_pink("Dev-env-triggered Alembic migration enabled for #{appname}")
  puts colorize_yellow('*********************************************************************')
  puts colorize_yellow('**                                                                 **')
  puts colorize_yellow('**                            WARNING!                             **')
  puts colorize_yellow('**                                                                 **')
  puts colorize_yellow('**              DEV-ENV_TRIGGERED ALEMBIC MIGRATION                **')
  puts colorize_yellow('**       IS DEPRECATED AND WILL BE REMOVED IN A FUTURE RELEASE     **')
  puts colorize_yellow('**                                                                 **')
  puts colorize_yellow('**           This app has set perform_alembic_migration            **')
  puts colorize_yellow('**                to true in its configuration.yml                 **')
  puts colorize_yellow('**                                                                 **')
  puts colorize_yellow('**                                                                 **')
  puts colorize_yellow('*********************************************************************')
  sleep(3)
end

def start_postgres_for_alembic(postgres_version)
  container = postgres_container(postgres_version)
  return if container == ''

  run_command_noshell(ENV['DC_CMD'].split(' ') + ['up', '-d', container])
  # Better not run anything until postgres is ready to accept connections...
  puts colorize_lightblue("Waiting for Postgres #{postgres_version} to finish initialising")

  while run_command_noshell(['docker', 'exec', container, 'pg_isready', '-h', 'localhost']) != 0
    puts colorize_yellow('Postgres is unavailable - sleeping')
    sleep(1)
  end

  # Sleep 3 more seconds to allow the root user to be set up if needed
  sleep(3)

  puts colorize_green("Postgres #{postgres_version} is ready")
end
