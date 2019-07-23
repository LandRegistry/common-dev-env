#!/usr/bin/ruby

def check_plugins(plugins)
  no_missing = true
  installed_plugins = []

  puts colorize_lightblue("Checking plugins...")

  raw_output = `vagrant plugin list`
  raw_list = raw_output.split("\n")

  raw_list.each do |plugin|
    # skip lines that we dont care about (like version pin info)
    if plugin.index("(") == nil
      next
    end
    if plugin.index("\e[0m") != nil
      first = plugin.index("\e[0m")  + 4
    else
      first = 0
    end
    plugin_name = plugin.slice((first)..(plugin.index("(")-1)).strip
    installed_plugins.push(plugin_name)
  end

  plugins.each_with_index do |plugin, index|
    if not installed_plugins.include? plugin
      puts colorize_lightblue(" - Missing '#{plugin}'!")
      plg_command = "vagrant plugin install #{plugin}"
      if run_command(plg_command) != 0
        puts colorize_red(" - Could not install plugin '#{plugin}'. ")
        exit -1
      else
        no_missing = false
      end
    end
  end

  if no_missing
    puts colorize_green(" - All plugins already satisfied")
  else
    puts colorize_green(" - Plugins installed")
  end
  [no_missing, installed_plugins]
end
