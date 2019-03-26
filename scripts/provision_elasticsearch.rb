require_relative 'utilities'
require_relative 'commodities'
require 'yaml'

def provision_elasticsearch(root_loc)
  puts colorize_lightblue('Searching for Elasticsearch initialisation scripts in the apps')
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  started = false
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for init scripts
    # if the app specifically specifies elasticsearch in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'elasticsearch')

    # Load any SQL contained in the apps into the docker commands list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/elasticsearch-fragment.sh")
      started = start_elasticsearch(root_loc, appname, started)
    else
      puts colorize_yellow("#{appname} says it uses Elasticsearch but doesn't contain an init script. Oh well, " \
                           'onwards we go!')
    end
  end
end

def start_elasticsearch(root_loc, appname, started)
  puts colorize_pink("Found some in #{appname}")
  if commodity_provisioned?(root_loc, appname, 'elasticsearch')
    puts colorize_yellow("Elasticsearch has previously been provisioned for #{appname}, skipping")
  else
    unless started
      run_command('docker-compose up -d elasticsearch')
      # Better not run anything until elasticsearch is ready to accept connections...
      puts colorize_lightblue('Waiting for Elasticsearch to finish initialising')

      loop do
        cmd_output = []
        run_command('curl --write-out "%{http_code}" --silent --output /dev/null http://localhost:9200', cmd_output)
        break if cmd_output.include? '200'

        puts colorize_yellow('Elasticsearch is unavailable - sleeping')
        sleep(3)
      end

      puts colorize_green('Elasticsearch is ready')
      started = true
    end
    run_command("sh #{root_loc}/apps/#{appname}/fragments/elasticsearch-fragment.sh http://localhost:9200")
    # Update the .commodities.yml to indicate that elasticsearch has now been provisioned
    set_commodity_provision_status(root_loc, appname, 'elasticsearch', true)
  end
  started
end
