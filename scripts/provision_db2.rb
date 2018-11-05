require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_db2(root_loc)
  puts colorize_lightblue('Searching for db2 initialisation SQL in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  database_initialised = false
  started = false

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies db2 in it's commodity list
    unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
      puts colorize_red("No configuration.yml found for #{appname}")
      next
    end
    next unless commodity_required?(root_loc, appname, 'db2')

    unless started
      run_command('docker-compose up --build -d --force-recreate db2')
      started = true
    end

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/db2-init-fragment.sql")
      database_initialised = process_db2_fragment(root_loc, appname, database_initialised)
    else
      puts colorize_yellow("#{appname} says it uses DB2 but doesn't contain an init SQL file. Oh well, onwards we " \
                            'go!')
    end
    puts colorize_lightblue("Completed #{appname} table sql fragment")
  end
end

def process_db2_fragment(root_loc, appname, database_initialised)
  result = false
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'db2')
    puts colorize_yellow("DB2 has previously been provisioned for #{appname}, skipping")
  else
    unless database_initialised
      init_db2
      result = true
    end
    init_sql(root_loc, appname)
  end
  result
end

def init_sql(root_loc, appname)
  # See comments in provision_postgres.rb for why we are doing it this way
  run_command('tar -c --transform "s|db2-init-fragment.sql|' + appname + '-init.sql|"' \
              " -C #{root_loc}/apps/#{appname}/fragments" \
              ' db2-init-fragment.sql' \
              ' | docker cp - db2:/')

  run_command('docker exec db2 bash -c "chmod o+r /' + appname + '-init.sql"')

  exit_code = run_command('docker exec -u db2inst1 db2 bash -c "~/sqllib/bin/db2 -tvf /' + appname + '-init.sql"')
  # Just in case a fragment hasn't disconnected from it's DB, let's do it now so the next fragment doesn't fail
  # when doing it's CONNECT TO
  run_command('docker exec -u db2inst1 db2 bash -c "~/sqllib/bin/db2 disconnect all"')

  if ![0, 2, 4, 6].include?(exit_code)
    # if exit_code != 6 && exit_code != 0 && exit_code != 2 && exit_code != 4
    puts colorize_red("Something went wrong with the table setup. Exitcode - #{exit_code}")
  else
    puts colorize_yellow("Database(s) and Table(s) created correctly. Exitcode - #{exit_code}.\n" \
                         'Exit code 4 tends to mean Database already exists. 6 - table already exists. 2 - ' \
                         "index already exists\n" \
                         'If in doubt read the above output carefully for the exact reason')
    set_commodity_provision_status(root_loc, appname, 'db2', true)
  end
end

def init_db2
  # Better not run anything until DB2 is ready to accept connections...
  puts colorize_lightblue('Waiting for DB2 to finish initialising')
  command_output = []
  until command_output.grep(/^1/).any?
    command_output.clear
    run_command('docker exec -u db2inst1 db2 ps -eaf|grep -i db2sysc | wc -l', command_output)
    puts colorize_yellow('DB2 is unavailable - sleeping')
    sleep(1)
  end
  puts colorize_green('DB2 is ready')
end
