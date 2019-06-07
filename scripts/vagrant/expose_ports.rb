#!/usr/bin/env ruby

require 'yaml'

def is_commodity?(root_loc, commodity)
  is_commodity = false # initialise

  return is_commodity unless File.exists?("#{root_loc}/.commodities.yml")

  commodities = YAML.load_file("#{root_loc}/.commodities.yml")
  commodities["commodities"].each do |commodity_name|
    if commodity == commodity_name
      is_commodity = true
      break
    end
  end

  is_commodity
end

def create_port_forwards(root_loc, vagrantconfig)
  port_list = get_port_list(root_loc)
  puts colorize_pink("Exposing ports #{port_list}")
  # If applications have ports assigned, let's map these to the host machine
  port_list.each do |port|
    host_port = port.split(":")[0].to_i
    guest_port = port.split(":")[1].to_i
    vagrantconfig.vm.network :forwarded_port, guest: guest_port, host: host_port
  end
end

def get_port_list(root_loc)
  puts colorize_lightblue("Searching for ports to forward")
  require 'yaml'
  root_loc = root_loc

  # Put all the app ports into an array
  port_list = []

  if File.exists?("#{root_loc}/dev-env-config/configuration.yml")
    config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

    # Loop through the apps, find the compose fragment, find the host port within
    # the fragment add it to port_list
    if config["applications"]
      config["applications"].each do |appname, appconfig|
        # If this app is docker, add it's compose to the list
        if File.exists?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")
          compose_file = YAML.load_file("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")

          compose_file["services"].each do |composeappname, composeappconfig|
            # If the compose file has a port section
            if composeappconfig.key?("ports")
              # Expose each port in the list
              composeappconfig["ports"].each do |port|
                app_host_port = port.split(":")[0]
                port_list.push("#{app_host_port}:#{app_host_port}")
              end
            end
          end
        end
      end
    end
  end

  if is_commodity?(root_loc, "postgres")
    port_list.push("15432:5432")
  end

  # If rabbitmq is being used then expose the rabbitmq admin port
  if is_commodity?(root_loc, "rabbitmq")
    port_list.push("35672:5672")
    port_list.push("45672:15672")
  end

  if is_commodity?(root_loc, "db2")
    port_list.push("50000:50000")
  end

  if is_commodity?(root_loc, "elasticsearch")
    port_list.push("19200:9200")
    port_list.push("19300:9300")
  end

  if is_commodity?(root_loc, "elasticsearch5")
    port_list.push("19202:9202")
    port_list.push("19302:9302")
  end

  if is_commodity?(root_loc, "nginx")
    port_list.push("80:80")
    port_list.push("443:443")
  end

  if is_commodity?(root_loc, "redis")
    port_list.push("16379:6379")
  end

  if is_commodity?(root_loc, "swagger")
    port_list.push("5101:5101")
  end

  if is_commodity?(root_loc, "wiremock")
    port_list.push("5017:5017")
  end

  return port_list
end
