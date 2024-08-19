require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_elasticsearch6(root_loc)
  puts colorize_lightblue('Searching for elasticsearch6 initialisation scripts in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  started = false
  return unless config['applications']

  config['applications'].each_key do |appname|
    # To help enforce the accuracy of the app's dependency file, only search for init scripts
    # if the app specifically specifies elasticsearch in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'elasticsearch6')

    # Run any script contained in the app
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/elasticsearch6-fragment.sh")
      started = start_elasticsearch6(root_loc, appname, started)
    else
      puts colorize_yellow("#{appname} says it uses Elasticsearch 6 but doesn't contain an init script. Oh well, " \
                            'onwards we go!')
    end
  end
end

def start_elasticsearch6(root_loc, appname, started)
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'elasticsearch6')
    puts colorize_yellow("Elasticsearch6 has previously been provisioned for #{appname}, skipping")
  else
    unless started
      run_command("#{ENV['DC_CMD']} up -d elasticsearch6")
      # Better not run anything until elasticsearch is ready to accept connections...
      puts colorize_lightblue('Waiting for Elasticsearch 6 to finish initialising')

      loop do
        cmd_output = []
        run_command('curl --write-out "%{http_code}" --silent --output /dev/null http://localhost:9202', cmd_output)
        break if cmd_output.include? '200'

        puts colorize_yellow('Elasticsearch 6 is unavailable - sleeping')
        sleep(3)
      end

      puts colorize_green('Elasticsearch 6 is ready')
      started = true
    end
    run_command("sh #{root_loc}/apps/#{appname}/fragments/elasticsearch6-fragment.sh http://localhost:9202")
    # Update the .commodities.yml to indicate that elasticsearch6 has now been provisioned
    set_commodity_provision_status(root_loc, appname, 'elasticsearch6', true)
  end
  started
end
