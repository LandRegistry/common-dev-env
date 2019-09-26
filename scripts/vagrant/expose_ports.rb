require 'yaml'

def commodity?(root_loc, commodity)
  is_commodity = false # initialise

  return is_commodity unless File.exist?("#{root_loc}/.commodities.yml")

  commodities = YAML.load_file("#{root_loc}/.commodities.yml")
  commodities['commodities'].each do |commodity_name|
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
    host_port = port.split(':')[0].to_i
    guest_port = port.split(':')[1].to_i
    vagrantconfig.vm.network :forwarded_port, guest: guest_port, host: host_port
  end
end

def get_port_list(root_loc)
  puts colorize_lightblue('Searching for ports to forward')

  # Put all the app ports into an array
  port_list = add_app_ports(root_loc)

  add_db_ports(root_loc, port_list)

  add_es_ports(root_loc, port_list)

  add_auth_ports(root_loc, port_list)

  # If rabbitmq is being used then expose the rabbitmq admin port
  if commodity?(root_loc, 'rabbitmq')
    port_list.push('35672:5672')
    port_list.push('45672:15672')
  end

  if commodity?(root_loc, 'nginx')
    port_list.push('80:80')
    port_list.push('443:443')
  end

  port_list.push('16379:6379') if commodity?(root_loc, 'redis')

  port_list.push('5101:5101') if commodity?(root_loc, 'swagger')

  port_list.push('5017:5017') if commodity?(root_loc, 'wiremock')

  port_list
end

def add_es_ports(root_loc, port_list)
  if commodity?(root_loc, 'elasticsearch')
    port_list.push('19200:9200')
    port_list.push('19300:9300')
  end

  return unless commodity?(root_loc, 'elasticsearch5')

  port_list.push('19202:9202')
  port_list.push('19302:9302')
end

def add_db_ports(root_loc, port_list)
  port_list.push('50000:50000') if commodity?(root_loc, 'db2')

  port_list.push('50001:50001') if commodity?(root_loc, 'db2_devc')

  port_list.push('50002:50002') if commodity?(root_loc, 'db2_community')

  port_list.push('15432:5432') if commodity?(root_loc, 'postgres')

  port_list.push('15433:5433') if commodity?(root_loc, 'postgres-9.6')
end

def add_auth_ports(root_loc, port_list)
  port_list.push('1389:1389') if commodity?(root_loc, 'auth') # LDAP
  port_list.push('8180:8180') if commodity?(root_loc, 'auth') # Keycloak
end

def add_app_ports(root_loc)
  port_list = []
  return port_list unless File.exist?("#{root_loc}/dev-env-config/configuration.yml")

  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")

  # Loop through the apps, find the compose fragment, find the host port within
  # the fragment add it to port_list
  if config['applications']
    config['applications'].each do |appname, _appconfig|
      # If this app is docker, add it's compose to the list
      next unless File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")

      compose_file = YAML.load_file("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.yml")

      add_service_ports(compose_file, port_list)
    end

    # Do it again for Compose 3.7 files, as we don't know which will be used at this point
    config['applications'].each do |appname, _appconfig|
      # If this app is docker, add it's compose to the list
      next unless File.exist?("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.3.7.yml")

      compose_file = YAML.load_file("#{root_loc}/apps/#{appname}/fragments/docker-compose-fragment.3.7.yml")

      add_service_ports(compose_file, port_list)
    end
  end

  port_list
end

def add_service_ports(compose_file, port_list)
  compose_file['services'].each do |_composeappname, composeappconfig|
    # If the compose file has a port section
    next unless composeappconfig.key?('ports')

    # Expose each port in the list
    composeappconfig['ports'].each do |port|
      app_host_port = port.split(':')[0]
      port_list.push("#{app_host_port}:#{app_host_port}")
    end
  end
end
