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
    # If this app is docker, add its compose to the list
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

  compose_counts = {
    '2' => 0,
    '3.7' => 0
  }

  config['applications'].each do |appname, _appconfig|
    compose_fragments = Dir["#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment*.yml"]
    compose_fragments.each do |fragment|
      basename = File.basename(fragment)
      if basename == 'docker-compose-fragment.yml'
        compose_counts['2'] += 1
      elsif basename == 'docker-compose-fragment.3.7.yml'
        compose_counts['3.7'] += 1
      else
        puts colorize_yellow("Unsupported fragment: #{basename}")
      end
    end
  end

  compose_version = get_consensus(compose_counts, config['applications'].length)
  puts colorize_lightblue("Selecting compose version #{compose_version}")
  compose_version
end

def get_consensus(compose_counts, app_count)
  preference = nil
  compose_counts.each do |version, count|
    preference = highest_version(preference, version) if count == app_count
  end

  return preference unless preference.nil?

  puts colorize_red('Applications have a mix of docker compose fragments versions. Unable to proceed.')
  exit 1
end

def highest_version(version_a, version_b)
  return version_a if version_a.to_f > version_b.to_f

  version_b
end

def fragment_filename(compose_version)
  if compose_version == '3.7'
    'docker-compose-fragment.3.7.yml'
  else
    'docker-compose-fragment.yml'
  end
end
