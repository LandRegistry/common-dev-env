require_relative 'utilities'
require 'yaml'

def provision_nginx(root_loc)
  puts colorize_lightblue('Searching for NGINX conf files in the apps')

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  started = false
  config['applications'].each do |appname, _appconfig|
    # To help enforce the accuracy of the app's dependency file, only search for a conf file
    # if the app specifically specifies nginx in it's commodity list
    next unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
    next unless commodity_required?(root_loc, appname, 'nginx')

    started = build_nginx(root_loc, appname, started)
  end
end

def build_nginx(root_loc, appname, already_started)
  # Load any conf files contained in the apps into the docker commands list
  started = already_started
  if File.exist?("#{root_loc}/apps/#{appname}/fragments/nginx-fragment.conf")
    puts colorize_pink("Found some in #{appname}")
    if commodity_provisioned?(root_loc, appname, 'nginx')
      puts colorize_yellow("NGINX has previously been provisioned for #{appname}, skipping")
    else
      unless started
        run_command('docker-compose up -d --no-deps nginx')
        started = true
      end
      # See comments in provision_postgres.rb for why we are doing it this way
      run_command('tar -c' \
                  " -C #{root_loc}/apps/#{appname}/fragments" \
                  ' nginx-fragment.conf' \
                  ' | docker cp - nginx:/etc/nginx/configs/')

      # Rename the file so it is unique and wont get overwritten by any others we copy up
      # Also, GitBash needs the inner quotes to be doubles
      run_command('docker exec nginx bash -c "' \
        "mv /etc/nginx/configs/nginx-fragment.conf /etc/nginx/configs/#{appname}-nginx-fragment.conf" \
        '"')

      # Update the .commodities.yml to indicate that NGINX has now been provisioned
      set_commodity_provision_status(root_loc, appname, 'nginx', true)
    end
  else
    puts colorize_yellow("#{appname} says it uses NGINX but doesn't contain a conf file. Oh well, onwards we go!")
  end
  started
end
