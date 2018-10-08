require_relative 'utilities'

def prepare_compose(root_loc, file_list_loc)
  require 'yaml'
  root_loc = root_loc

  # Put all the apps into an array, as their compose file argument
  commodity_list = get_apps(root_loc)

  # Load any commodities into the docker compose list
  commodities = YAML.load_file("#{root_loc}/.commodities.yml")
  if commodities.key?('commodities')
    commodities['commodities'].each do |commodity_info|
      commodity_list.push("#{root_loc}/scripts/docker/#{commodity_info}/docker-compose-fragment.yml")
    end
  end

  # Put the compose arguments into a file for later retrieval
  # Note that Compose on Windows needs semicolons separating the fragments
  File.open(file_list_loc, 'w') do |f|
    if Gem.win_platform?
      f.write(commodity_list.join(';'))
    else
      f.write(commodity_list.join(':'))
    end
  end
end

def get_apps(root_loc)
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  commodity_list = []
  if config['applications']
    config['applications'].each do |appname, _appconfig|
      # If this app is docker, add it's compose to the list
      if File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
        commodity_list.push("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
      end
    end
  end
  commodity_list
end
