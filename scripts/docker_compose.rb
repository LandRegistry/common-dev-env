require_relative 'utilities'

def prepare_compose(root_loc, file_list_loc)
  require 'yaml'
  root_loc = root_loc

  commodity_list = []
  # When using the COMPOSE_FILE env var, the first fragment in the list is used
  # as the path that all relative paths in further fragments are based on.
  # By making this consistently /apps, fragments do not need to rely on ${PWD}
  # which can vary depending on where the user happens to be when they issue the
  # command (e.g. status). We do this by making the first file an empty fragment
  # that lives in /apps
  commodity_list.push("#{root_loc}/apps/root-docker-compose-fragment.yml")

  # Put all the apps into an array, as their compose file argument
  get_apps(root_loc, commodity_list)

  # Load any commodities into the docker compose list
  if File.exist?("#{root_loc}/.commodities.yml")
    commodities = YAML.load_file("#{root_loc}/.commodities.yml")
    if commodities.key?('commodities')
      commodities['commodities'].each do |commodity_info|
        commodity_list.push("#{root_loc}/scripts/docker/#{commodity_info}/docker-compose-fragment.yml")
      end
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

def get_apps(root_loc, commodity_list)
  if !File.exist?("#{root_loc}/dev-env-config/configuration.yml")
    puts colorize_yellow("No dev-env-config found. Maybe this is a fresh box... if so, you need to do \"source run.sh up\"")
    return
  end

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # If this app is docker, add it's compose to the list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
      commodity_list.push("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
    end
  end
end
