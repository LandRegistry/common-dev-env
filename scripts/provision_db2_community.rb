require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_db2_community(root_loc, new_containers)
  puts colorize_lightblue('Searching for db2_community initialisation SQL in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  # Did the container previously exist, if not then we MUST provision regardless of .commodities value
  new_db_container = false
  if new_containers.include?('db2_community')
    new_db_container = true
    puts colorize_yellow('The DB2 Community container has been newly created - '\
                         'provision status in .commodities will be ignored')
  end

  database_initialised = false

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies db2_community in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'db2_community')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/db2-community-init-fragment.sql")
      database_initialised = process_db2_community_fragment(root_loc, appname, database_initialised, new_db_container)
    else
      puts colorize_yellow("#{appname} says it uses DB2 Community but doesn't contain an init SQL file.
          Oh well, onwards we go!")
    end
  end
end

def process_db2_community_fragment(root_loc, appname, database_initialised, new_db_container)
  result = database_initialised
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'db2_community') && !new_db_container
    puts colorize_yellow("DB2 Community has previously been provisioned for #{appname}, skipping")
  else
    unless database_initialised
      init_db2_community
      result = true
    end
    init_db2_community_sql(root_loc, appname)
  end
  result
end

def init_db2_community_sql(root_loc, appname)
  # See comments in provision_postgres.rb for why we are doing it this way
  run_command('tar -c' \
              " -C #{root_loc}/apps/#{appname}/fragments" \
              ' db2-community-init-fragment.sql' \
              ' | docker cp - db2_community:/')

  run_command('docker exec db2_community bash -c "chmod o+r /db2-community-init-fragment.sql"')

  cmd = 'docker exec -u db2inst1 db2_community bash -c "~/sqllib/bin/db2 -tvf /db2-community-init-fragment.sql"'
  exit_code = run_command(cmd)
  # Just in case a fragment hasn't disconnected from it's DB, let's do it now so the next fragment doesn't fail
  # when doing it's CONNECT TO
  run_command('docker exec -u db2inst1 db2_community bash -c "~/sqllib/bin/db2 disconnect all"')

  puts colorize_lightblue("Completed #{appname} table sql fragment")

  if ![0, 2, 4, 6].include?(exit_code)
    # if exit_code != 6 && exit_code != 0 && exit_code != 2 && exit_code != 4
    puts colorize_red("Something went wrong with the table setup. Exitcode - #{exit_code}")
  else
    puts colorize_yellow("Database(s) and Table(s) created correctly. Exitcode - #{exit_code}.\n" \
                         'Exit code 4 tends to mean Database already exists. 6 - table already exists. 2 - ' \
                         "index already exists\n" \
                         'If in doubt read the above output carefully for the exact reason')
    set_commodity_provision_status(root_loc, appname, 'db2_community', true)
  end
end

def init_db2_community
  # Start DB2 Community
  run_command('docker-compose --compatibility up -d db2_community')

  # Better not run anything until DB2 is ready to accept connections...
  puts colorize_lightblue('Waiting for DB2 Community to finish initialising (this will take a few minutes)')
  command_output = []
  command_outcode = 1
  until command_outcode.zero? && check_healthy_output(command_output)
    command_output.clear
    command_outcode = run_command('docker inspect --format="{{json .State.Health.Status}}" db2_community',
                                  command_output)
    puts colorize_yellow('DB2 Community is unavailable - sleeping')
    sleep(5)
  end
  puts colorize_green('DB2 Community is ready')
  # One more sleep to ensure user gets set up
  sleep(7)
end
