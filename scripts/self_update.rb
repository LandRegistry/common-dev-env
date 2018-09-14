require_relative 'utilities'
require 'highline/import'
require 'json'
require 'net/http'
require 'rubygems'
require 'uri'

def self_update(root_loc, this_version)
  latest_version = retrieve_version

  # If latest_version is nil, retrieve_version has already displayed an error
  if !latest_version.nil? && Gem::Version.new(latest_version[0]) > Gem::Version.new(this_version)
    prompt_and_update(root_loc, latest_version)
  else
    puts colorize_green('This is the latest version.') unless latest_version.nil?
  end
rescue StandardError => e
  puts e
  puts colorize_yellow("There was an error retrieving the current dev-env version. I'll just get on with starting " \
                       'the machine.')
  puts colorize_yellow('Continuing in 5 seconds...')
  sleep(5)
end

def prompt_and_update(root_loc, latest_version)
  puts colorize_yellow("A new version is available - v#{latest_version[0]}")
  puts colorize_yellow('Changes:')
  puts colorize_yellow(latest_version[1])
  puts ''

  # Have we already asked the user to update today?
  ask_update = if refused_today?(root_loc)
                 false
               else
                 true
               end
  confirm_and_update(root_loc) if ask_update
end

def refused_today?(root_loc)
  update_check_file = "#{root_loc}/.update-check-context"
  return false unless File.exist?(update_check_file)
  parsed_date = Date.strptime(File.read(update_check_file), '%Y-%m-%d')
  if Date.today == parsed_date
    puts colorize_yellow("You've already said you don't want to update today, so I won't ask again. To update" \
                          ' manually, run git pull.')
    puts ''
    true
  else
    # We have not asked today yet, delete the file
    File.delete(update_check_file)
    false
  end
end

def confirm_and_update(root_loc)
  confirm = nil
  confirm = ask colorize_yellow('Would you like to update now? (y/n) ') until %w[Y y N n].include?(confirm)
  if confirm.upcase.start_with?('Y')
    # (try to) run the update
    run_update(root_loc)
  else
    puts ''
    puts colorize_yellow("Okay. I'll ask again tomorrow. If you want to update in the meantime, simply " \
                          'run git pull yourself.')
    puts colorize_yellow('Continuing in 5 seconds...')
    puts ''
    File.write("#{root_loc}/.update-check-context", Date.today.to_s)
    sleep(5)
  end
end

def run_update(root_loc)
  if run_command('git -C ' + root_loc + ' pull') != 0
    puts colorize_yellow("There was an error retrieving the new dev-env. Sorry. I'll just get on with " \
                          'starting the machine.')
    puts colorize_yellow('Continuing in 5 seconds...')
    sleep(5)
  else
    puts colorize_yellow('Update successful.')
    puts colorize_yellow("Please rerun your command (source run.sh #{ARGV.join(' ')})")
    exit 1
  end
end

def retrieve_version
  # Check for new version (using a snippet)
  versioncheck_uri = URI.parse('https://api.github.com/repos/LandRegistry/common-dev-env/releases/latest')
  http = Net::HTTP.new(versioncheck_uri.host, versioncheck_uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(versioncheck_uri.request_uri)
  response = http.request(request)

  if response.code == '200'
    result = JSON.parse(response.body)
    return result['tag_name'].sub(/^v/, ''), result['body']  # Remove v if it starts with it
  else
    puts colorize_yellow("There was an error retrieving the current dev-env version (HTTP code #{response.code})." \
                         " I'll just get on with starting the machine.")
    puts colorize_yellow('Continuing in 5 seconds...')
    sleep(5)
    nil
  end
end
