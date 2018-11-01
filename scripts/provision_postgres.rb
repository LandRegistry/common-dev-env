require_relative 'utilities'
require 'yaml'

def provision_postgres(root_loc)
  puts colorize_lightblue('Searching for postgres initialisation SQL in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  started = false
  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies postgres in it's commodity list
    unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
      puts colorize_red("No configuration.yml found for #{appname}")
      next
    end
    next unless commodity_required?(root_loc, appname, 'postgres')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/postgres-init-fragment.sql")
      started = start_postgres_maybe(root_loc, appname, started)
    else
      puts colorize_yellow("#{appname} says it uses Postgres but doesn't contain an init SQL file. " \
                           'Oh well, onwards we go!')
    end
  end
end

def start_postgres_maybe(root_loc, appname, started)
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'postgres')
    puts colorize_yellow("Postgres has previously been provisioned for #{appname}, skipping")
  else
    started = start_postgres(root_loc, appname, started)
  end
  started
end

def start_postgres(root_loc, appname, started)
  unless started
    run_command('docker-compose up --build -d --force-recreate postgres')
    # Better not run anything until postgres is ready to accept connections...
    run_command('echo Waiting for postgres to finish initialising')
    run_command("#{root_loc}/scripts/docker/postgres/wait-for-it.sh localhost")

    started = true
  end
  # Copy the app's init sql into postgres (renaming it along the way).
  # We don't just use docker cp with a plain file path as the source, to deal with the WSL + DockerForWindows
  # combination.
  # Therefore we pipe a tarball (tarball is docker cp requirement) into it instead, handy as tar runs in the
  # same context as ruby and understands it's paths!
  run_command("tar -c --transform 's|postgres-init-fragment.sql|#{appname}-init.sql|' " \
              "-C #{root_loc}/apps/#{appname}/fragments postgres-init-fragment.sql | docker cp - postgres:/")

  run_command("docker exec postgres psql -q -f '/#{appname}-init.sql'")
  # Update the .commodities.yml to indicate that postgres has now been provisioned
  set_commodity_provision_status(root_loc, appname, 'postgres', true)
  started
end
