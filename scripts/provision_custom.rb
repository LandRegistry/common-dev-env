require_relative 'utilities'

def create_custom_provision(root_loc)
  root_loc = root_loc
  if File.exist?("#{root_loc}/.custom_provision.yml")
    puts colorize_green('Found an existing .custom_provision file.')
    return
  end

  # Create the base file structure
  puts colorize_green("Did not find a .custom_provision file. I'll create a new one.")
  custom_file = {
    'version' => '1',
    'applications' => []
  }

  # Write the file
  File.open("#{root_loc}/.custom_provision.yml", 'w') { |f| f.write(custom_file.to_yaml) }
end

def custom_provisioned?(root_loc, app_name)
  is_provisioned = false # initialise
  if File.exist?("#{root_loc}/.custom_provision.yml")
    custom_file = YAML.load_file("#{root_loc}/.custom_provision.yml")
    custom_file['applications'].each do |provisioned_app_name|
      if provisioned_app_name == app_name
        is_provisioned = true
        break
      end
    end
  end
  is_provisioned
end

def set_custom_provisioned(root_loc, app_name)
  return unless File.exist?("#{root_loc}/.custom_provision.yml")

  custom_file = YAML.load_file("#{root_loc}/.custom_provision.yml")
  custom_file['applications'].push(app_name)
  File.open("#{root_loc}/.custom_provision.yml", 'w') { |f| f.write(custom_file.to_yaml) }
end

def provision_custom(root_loc)
  puts colorize_lightblue('Searching for custom provisioning scripts in the apps')
  require 'yaml'

  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  config['applications'].each do |appname, _appconfig|
    # Load any scripts contained in the apps into the commands list
    run_onetime_custom_provision(root_loc, appname)

    # Now do provision scripts that run on every up
    run_always_custom_provision(root_loc, appname)
  end
end

def run_onetime_custom_provision(root_loc, appname)
  return unless File.exist?("#{root_loc}/apps/#{appname}/fragments/custom-provision.sh")

  puts colorize_pink("Found one (once-only) in #{appname}")
  if custom_provisioned?(root_loc, appname)
    puts colorize_yellow("Custom provision script has already been run for #{appname}, skipping")
  else
    run_command("sh #{root_loc}/apps/#{appname}/fragments/custom-provision.sh")
    # Update the .custom_provision.yml to indicate that the script has been run
    set_custom_provisioned(root_loc, appname)
  end
end

def run_always_custom_provision(root_loc, appname)
  return unless File.exist?("#{root_loc}/apps/#{appname}/fragments/custom-provision-always.sh")

  puts colorize_pink("Found one (always) in #{appname}")
  run_command("sh #{root_loc}/apps/#{appname}/fragments/custom-provision-always.sh")
end
