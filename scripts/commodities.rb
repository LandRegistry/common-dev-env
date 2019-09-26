require_relative 'utilities'
require 'fileutils'
require 'yaml'

def create_commodities_list(root_loc)
  unless File.exist?("#{root_loc}/dev-env-config/configuration.yml")
    puts colorize_yellow('No dev-env-config found. Maybe this is a fresh box... '\
                         'if so, you need to do "source run.sh up"')
    exit 1
  end

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

  # Put all the commodities for all apps into an array
  commodity_list, app_to_commodity_map = which_app_needs_what(root_loc, config)
  commodity_list.push('logging') unless commodity_list.include?('logging')
  commodity_file = get_commodity_file(root_loc)

  # Rebuild the the master list
  commodity_file['commodities'] = commodity_list
  add_missing_pairings(app_to_commodity_map, commodity_file)

  # Write the commodity information to a file
  File.open("#{root_loc}/.commodities.yml", 'w') { |f| f.write(commodity_file.to_yaml) }
end

def add_missing_pairings(app_to_commodity_map, commodity_file)
  cf_app_list = commodity_file['applications']
  # Add any missing app/commodity pairings to the list
  app_to_commodity_map.each do |app_name, app_commodity_list|
    # App
    cf_app_list[app_name] = {} unless cf_app_list.key? app_name

    # Commodity
    app_commodity_list.each do |current_commodity|
      unless cf_app_list[app_name].key? current_commodity
        cf_app_list[app_name][current_commodity] = false
        puts colorize_pink("Found a new commodity dependency from #{app_name} to #{current_commodity}")
      end
    end
  end
end

def which_app_needs_what(root_loc, config)
  app_to_commodity_map = Hash.new([].freeze)
  commodity_list = []
  if config['applications']
    config['applications'].each do |appname, _appconfig|
      # Load any commodities into the list
      unless File.exist?("#{root_loc}/apps/#{appname}/configuration.yml")
        puts colorize_yellow("No configuration.yml found for #{appname}, assume no commodities & inexpensive startup")
        sleep(3)
        next
      end
      dependencies = YAML.load_file("#{root_loc}/apps/#{appname}/configuration.yml")

      next if dependencies.nil?
      next unless dependencies.key?('commodities')

      dependencies['commodities'].each do |appcommodity|
        commodity_list.push(appcommodity)
        app_to_commodity_map[appname] += [appcommodity]
      end
    end
  end
  [commodity_list.uniq, app_to_commodity_map]
end

def get_commodity_file(root_loc)
  if File.exist?("#{root_loc}/.commodities.yml")
    commodity_file = YAML.load_file("#{root_loc}/.commodities.yml")
    puts colorize_pink('Found an existing .commodities file.')
  else
    # Create the base file structure
    puts colorize_lightblue('Did not find any .commodities file. Creating a new one.')
    commodity_file = {
      'version' => '2',
      'commodities' => [],
      'applications' => {}
    }
  end
  commodity_file
end

def commodity_provisioned?(root_loc, app_name, commodity)
  commodity_file = YAML.load_file("#{root_loc}/.commodities.yml")
  commodity_file['applications'][app_name][commodity]
end

def set_commodity_provision_status(root_loc, app_name, commodity, status)
  commodity_file = YAML.load_file("#{root_loc}/.commodities.yml")
  commodity_file['applications'][app_name][commodity] = status
  File.open("#{root_loc}/.commodities.yml", 'w') { |f| f.write(commodity_file.to_yaml) }
end

def commodity_required?(root_loc, appname, commodity)
  dependencies = YAML.load_file("#{root_loc}/apps/#{appname}/configuration.yml")
  return false if dependencies.nil?

  dependencies.key?('commodities') && dependencies['commodities'].include?(commodity)
end

def commodity?(root_loc, commodity)
  is_commodity = false # initialise
  return false unless File.exist?("#{root_loc}/.commodities.yml")

  commodities = YAML.load_file("#{root_loc}/.commodities.yml")

  commodities['commodities'].each do |commodity_name|
    if commodity == commodity_name
      is_commodity = true
      break
    end
  end

  is_commodity
end

if $PROGRAM_NAME == __FILE__
  root_loc = File.expand_path('..', File.dirname(__FILE__))
  exit unless File.exist?("#{root_loc}/.commodities.yml")

  done_one = false
  # Is a commodity container being reset
  if commodity?(root_loc, ARGV[0])
    commodity_file = YAML.load_file("#{root_loc}/.commodities.yml")
    commodity_file['applications'].each do |app_name, _commodity|
      # If this app has provisioned this commodity, change to false as it hasn't any more!
      if commodity_provisioned?(root_loc, app_name, ARGV[0])
        set_commodity_provision_status(root_loc, app_name, ARGV[0], false)
        done_one = true
      end
    end
  end
  exit 99 if done_one
end
