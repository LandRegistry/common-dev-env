require_relative 'commodities'

require 'fileutils'
require 'yaml'

if $PROGRAM_NAME == __FILE__
  root_loc = File.expand_path('..', File.dirname(__FILE__))
  exit unless File.exist?("#{root_loc}/.commodities.yml")

  # Is a commodity container being reset
  commodity_name = container_to_commodity(ARGV[0])
  if commodity?(root_loc, commodity_name)
    commodity_file = YAML.load_file("#{root_loc}/.commodities.yml")
    commodity_file['applications'].each do |app_name, _commodity|
      next unless commodity_provisioned?(root_loc, app_name, commodity_name)

      puts colorize_yellow("At least one app has fragments for #{ARGV[0]}, so I'll provision everything again")
      provision_commodities(root_loc, [ARGV[0]])
      break
    end
  end
end
