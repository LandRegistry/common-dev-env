require_relative 'utilities'

def provision_alembic(root_loc)
  puts colorize_lightblue('Searching for alembic code')
  require 'yaml'
  root_loc = root_loc
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
    next unless commodity_required?(root_loc, appname, 'postgres')
    next unless File.exist?("#{root_loc}/apps/#{appname}/manage.py")

    unless started
      start_postgres_for_alembic(root_loc)
      started = true
    end
    puts colorize_pink("Found some in #{appname}")
    run_command("docker-compose run --rm #{appname} bash -c 'cd /src && export SQL_USE_ALEMBIC_USER=yes && " \
                "export SQL_PASSWORD=superroot && python3 manage.py db upgrade'")
  end
end

def start_postgres_for_alembic(root_loc)
  run_command('docker-compose up --build -d --force-recreate postgres')
  run_command('docker-compose up --build -d --force-recreate logstash')
  # Better not run anything until postgres is ready to accept connections...
  run_command('echo Waiting for postgres to finish initialising')
  run_command("#{root_loc}/scripts/docker/postgres/wait-for-it.sh localhost")
end
