require_relative 'utilities'

def prepare_compose(root_loc, file_list_loc)
  require 'yaml'
  root_loc = root_loc

  commodity_list = []
  compose_version = choose_compose_version(root_loc)
  # When using the COMPOSE_FILE env var, the first fragment in the list is used
  # as the path that all relative paths in further fragments are based on.
  # By making this consistently /apps, fragments do not need to rely on ${PWD}
  # which can vary depending on where the user happens to be when they issue the
  # command (e.g. status). We do this by making the first file an empty fragment
  # that lives in /apps
  commodity_list.push("#{root_loc}/apps/root-#{fragment_filename(compose_version)}")

  # Put all the apps into an array, as their compose file argument
  get_apps(root_loc, commodity_list, compose_version)

  # Load any commodities into the docker compose list
  commodities = YAML.load_file("#{root_loc}/.commodities.yml")
  if commodities.key?('commodities')
    commodities['commodities'].each do |commodity_info|
      commodity_list.push("#{root_loc}/scripts/docker/#{commodity_info}/#{fragment_filename(compose_version)}")
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

def get_apps(root_loc, commodity_list, compose_version)
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # If this app is docker, add it's compose to the list
    if File.exist?("#{root_loc}/apps/#{appname}/fragments/#{fragment_filename(compose_version)}")
      commodity_list.push("#{root_loc}/apps/#{appname}/fragments/#{fragment_filename(compose_version)}")
    end
  end
end

def choose_compose_version(root_loc)
  # We can assume that the root fragment and commodity fragments all have 3 as an option
  # Check the apps to see if they all have a 2 or a 3
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  compose_2_count = 0
  compose_3_count = 0
  config['applications'].each do |appname, _appconfig|
    compose_2_count += 1 if File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
    compose_3_count += 1 if File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.3.yml")
  end

  fail_if_no_consensus(compose_2_count, compose_3_count, config['applications'].length)

  if compose_3_count == config['applications'].length
    puts colorize_lightblue('All applications have v3 docker compose files.')
    return 3
  end

  puts colorize_lightblue('All applications have v2 docker compose files.')
  2
end

def fail_if_no_consensus(compose_2_count, compose_3_count, app_count)
  return if (compose_2_count == app_count) || (compose_3_count == app_count)

  puts colorize_red('Applications have a mix of v2 and v3 docker compose fragments. Unable to proceed.')
  exit 1
end

def fragment_filename(compose_version)
  if compose_version == 3
    'docker-compose-fragment.3.yml'
  else
    'docker-compose-fragment.yml'
  end
end
