require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_db2_devc(root_loc)
  puts colorize_lightblue('Searching for db2_devc initialisation SQL in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  database_initialised = false

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init sql
    # if the app specifically specifies db2_devc in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'db2_devc')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/db2-devc-init-fragment.sql")
      database_initialised = process_db2_devc_fragment(root_loc, appname, database_initialised)
    else
      puts colorize_yellow("#{appname} says it uses DB2 Developer C but doesn't contain an init SQL file.
          Oh well, onwards we go!")
    end
  end
end

def process_db2_devc_fragment(root_loc, appname, database_initialised)
  result = database_initialised
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'db2_devc')
    puts colorize_yellow("DB2 Developer C has previously been provisioned for #{appname}, skipping")
  else
    unless database_initialised
      init_db2_devc
      result = true
    end
    init_db2_devc_sql(root_loc, appname)
  end
  result
end

def init_db2_devc_sql(root_loc, appname)
  # See comments in provision_postgres.rb for why we are doing it this way
  run_command('tar -c' \
              " -C #{root_loc}/apps/#{appname}/fragments" \
              ' db2-devc-init-fragment.sql' \
              ' | docker cp - db2_devc:/')

  run_command('docker exec db2_devc bash -c "chmod o+r /db2-devc-init-fragment.sql"')

  cmd = 'docker exec -u db2inst1 db2_devc bash -c "~/sqllib/bin/db2 -tvf /db2-devc-init-fragment.sql"'
  exit_code = run_command(cmd)
  # Just in case a fragment hasn't disconnected from it's DB, let's do it now so the next fragment doesn't fail
  # when doing it's CONNECT TO
  run_command('docker exec -u db2inst1 db2_devc bash -c "~/sqllib/bin/db2 disconnect all"')

  puts colorize_lightblue("Completed #{appname} table sql fragment")

  if ![0, 2, 4, 6].include?(exit_code)
    # if exit_code != 6 && exit_code != 0 && exit_code != 2 && exit_code != 4
    puts colorize_red("Something went wrong with the table setup. Exitcode - #{exit_code}")
  else
    puts colorize_yellow("Database(s) and Table(s) created correctly. Exitcode - #{exit_code}.\n" \
                         'Exit code 4 tends to mean Database already exists. 6 - table already exists. 2 - ' \
                         "index already exists\n" \
                         'If in doubt read the above output carefully for the exact reason')
    set_commodity_provision_status(root_loc, appname, 'db2_devc', true)
  end
end

def init_db2_devc
  # Start DB2 developer c
  run_command('docker-compose up -d db2_devc')

  # Better not run anything until DB2 is ready to accept connections...
  puts colorize_lightblue('Waiting for DB2 Developer C to finish initialising')
  command_output = []
  until command_output.grep(/1/).any?
    command_output.clear
    run_command('docker exec -u db2inst1 db2_devc ps -eaf|grep -i db2fmcd | wc -l', command_output)
    puts colorize_yellow('DB2 Developer C is unavailable - sleeping')
    sleep(1)
  end
  puts colorize_green('DB2 Developer C is ready')
end
