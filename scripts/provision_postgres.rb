require_relative 'utilities'
require 'yaml'

def postgres_container(postgres_version)
  case postgres_version
  when '13'
    'postgres-13'
  when '17'
    'postgres-17'
  else
    puts colorize_red("Unknown PostgreSQL version (#{postgres_version}) specified.")
    ''
  end
end

def provision_postgres(root_loc, new_containers, postgres_version)
  container = postgres_container(postgres_version)
  return if container == ''

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value
  new_db_container = false
  if new_containers.include?(container)
    new_db_container = true
    puts colorize_yellow("The Postgres #{postgres_version} container has been newly created - "\
                         'provision status in .commodities will be ignored')
  end

  started = false
  config['applications'].each_key do |appname|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies postgres in it's commodity list
    next unless postgres_required?(root_loc, appname, container)

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/postgres-init-fragment.sql")
      started = start_postgres_maybe(root_loc, appname, started, new_db_container, postgres_version)
    end
  end
end

def postgres_required?(root_loc, appname, container)
  File.exist?("#{root_loc}/apps/#{appname}/configuration.yml") &&
    commodity_required?(root_loc, appname, container_to_commodity(container))
end

def start_postgres_maybe(root_loc, appname, started, new_db_container, postgres_version)
  container = postgres_container(postgres_version)
  return if container == ''

  puts colorize_pink("Found Postgres init fragment SQL in #{appname}")
  if commodity_provisioned?(root_loc, appname, container_to_commodity(container)) && !new_db_container
    puts colorize_yellow("Postgres #{postgres_version} has previously been provisioned for #{appname}, skipping")
  else
    started = start_postgres(root_loc, appname, started, postgres_version)
  end
  started
end

def start_postgres(root_loc, appname, started, postgres_version)
  container = postgres_container(postgres_version)
  return if container == ''

  unless started
    run_command_noshell(ENV['DC_CMD'].split(' ') + ['up', '-d', container])
    # Better not run anything until postgres is ready to accept connections...
    puts colorize_lightblue("Waiting for Postgres #{postgres_version} to finish initialising")

    command_output = []
    command_outcode = 1
    until command_outcode.zero? && check_healthy_output(command_output)
      command_output.clear
      command_outcode = run_command("docker inspect --format=\"{{json .State.Health.Status}}\" #{container}",
                                    command_output)
      puts colorize_yellow("Postgres #{postgres_version} is unavailable - sleeping")
      sleep(3)
    end

    # Sleep 3 more seconds to allow the root user to be set up if needed
    sleep(3)

    puts colorize_green("Postgres #{postgres_version} is ready")
    started = true
  end

  run_initialisation(root_loc, appname, container)

  # Update the .commodities.yml to indicate that postgres has now been provisioned
  set_commodity_provision_status(root_loc, appname, container_to_commodity(container), true)
  started
end

def run_initialisation(root_loc, appname, container)
  # Copy the app's init sql into postgres then execute it with psql.
  # We don't just use docker cp with a plain file path as the source, to deal with WSL,
  # where LinuxRuby passes a path to WindowsDocker that it can't parse.
  # Therefore we create and pipe a tar file into docker cp instead, handy as tar runs in the
  # shell and understands Ruby's paths in both WSL and Git Bash!
  run_command("tar -c -C #{root_loc}/apps/#{appname}/fragments postgres-init-fragment.sql | docker cp - #{container}:/")
  puts colorize_pink("Executing SQL fragment for #{appname}...")
  run_command_noshell(['docker', 'exec', container, 'psql', '-q', '-f', 'postgres-init-fragment.sql'])
  puts colorize_pink('...done.')
end

# def show_postgres_warnings(root_loc)
#   config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
#   return unless config['applications']

#   warned_versions = []
#   config['applications'].each do |appname, _appconfig|
#     # Example
#     if postgres_required?(root_loc, appname, 'postgres') && !warned_versions.include?('postgres')
#       show_postgres94_warning()
#       warned_versions.append('postgres')
#     end
#   end
# end

# Example
# def show_postgres94_warning()
#   puts colorize_yellow('*******************************************************')
#   puts colorize_yellow('**                                                   **')
#   puts colorize_yellow('**                     WARNING!                      **')
#   puts colorize_yellow('**                                                   **')
#   puts colorize_yellow('**         POSTGRESQL 9.4 IS OUT OF SUPPPORT         **')
#   puts colorize_yellow('**                                                   **')
#   puts colorize_yellow('** PostgreSQL 9.4 is out of support. Please update   **')
#   puts colorize_yellow('** your service to use a supported version.          **')
#   puts colorize_yellow('**                                                   **')
#   puts colorize_yellow('*******************************************************')
# end
