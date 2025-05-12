require_relative 'utilities'

def prepare_compose(root_loc, file_list_loc)
  require 'yaml'

  commodity_list = []
  compose_variants = find_active_variants(root_loc)
  # When using the COMPOSE_FILE env var, the first fragment in the list is used
  # as the path that all relative paths in further fragments are based on.
  # By making this consistently /apps, fragments do not need to rely on ${PWD}
  # which can vary depending on where the user happens to be when they issue the
  # command (e.g. status). We do this by making the first file an empty fragment
  # that lives in /apps
  commodity_list.push("#{root_loc}/apps/root-compose-fragment.yml")

  # Put all the apps into an array, as their compose file argument
  get_apps(root_loc, commodity_list, compose_variants)

  # Load any commodities into the docker compose list
  if File.exist?("#{root_loc}/.commodities.yml")
    commodities = YAML.load_file("#{root_loc}/.commodities.yml")
    if commodities.key?('commodities')
      commodities['commodities'].each do |commodity_info|
        commodity_list.push("#{root_loc}/scripts/docker/#{commodity_info}/compose-fragment.yml")
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

def get_apps(root_loc, commodity_list, compose_variants)
  unless File.exist?("#{root_loc}/dev-env-config/configuration.yml")
    puts colorize_yellow('No dev-env-config found. Maybe this is a fresh box... '\
                         'if so, you need to do "source run.sh up"')
    return
  end

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  config['applications'].each_key do |appname|
    # If this app is docker, add its compose to the list
    if compose_variants.key?(appname)
      variant_fragment_filename = fragment_filename(compose_variants[appname])
      if File.exist?("#{root_loc}/apps/#{appname}/fragments/#{variant_fragment_filename}")
        commodity_list.push("#{root_loc}/apps/#{appname}/fragments/#{variant_fragment_filename}")
      end
    elsif File.exist?("#{root_loc}/apps/#{appname}/fragments/compose-fragment.yml")
      commodity_list.push("#{root_loc}/apps/#{appname}/fragments/compose-fragment.yml")
    end
  end
end

def find_active_variants(root_loc)
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  compose_variants = {}

  config['applications'].each_key do |appname|
    found_valid_fragment = false
    compose_fragments = Dir["#{root_loc}/apps/#{appname}/fragments/*compose-fragment*.yml"]

    compose_fragments.each do |fragment|
      basename = File.basename(fragment)
      case basename
      when 'compose-fragment.yml'
        found_valid_fragment = true
      when /compose-fragment\..+\.yml/
        variant_fragment_filename = validate_variant_fragment_filename(config, appname, basename)
        unless variant_fragment_filename.nil?
          compose_variants[appname] = variant_fragment_filename
          puts colorize_lightblue("#{appname}: Selected compose variant \"#{compose_variants[appname]}\"")
          found_valid_fragment = true
        end
      else
        puts colorize_yellow("Unsupported fragment in #{appname}: #{basename}")
      end
    end
    next if found_valid_fragment

    puts colorize_red("Cannot find a valid compose fragment file in #{appname}; no container will be created")
    puts colorize_yellow('Continuing in 3 seconds...')
    sleep(3)
  end

  compose_variants
end

def validate_variant_fragment_filename(config, appname, basename)
  variant_fragment_filename = basename.scan(/compose-fragment\.(.*?)\.yml/).flatten.first
  if config['applications'][appname].key?('variant') && config['applications'][appname]['variant'] \
    == variant_fragment_filename
    return variant_fragment_filename
  end

  nil
end

def highest_version(version_a, version_b)
  return 'unversioned' if version_a == 'unversioned' || version_b == 'unversioned'
  return '3.7' if version_a == '3.7' || version_b == '3.7'
  return '2' if version_a == '2' || version_b == '2'

  nil
end

def fragment_filename(compose_variant_name)
  if compose_variant_name.nil?
    'compose-fragment.yml'
  else
    "compose-fragment.#{compose_variant_name}.yml"
  end
end
