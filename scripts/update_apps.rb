require_relative 'utilities'
require 'yaml'

THREAD_COUNT = 3

def update_apps(root_loc)
  # Load configuration.yml into a Hash
  config = YAML.load_file("#{root_loc}/dev-env-config/configuration.yml")
  return unless config['applications']

  output_mutex = Mutex.new
  threads = []
  queue = Queue.new

  # Launch threads with our app-updating code in them.
  THREAD_COUNT.times do
    threads << Thread.new do
      loop do
        # Block on queue.pop until a nil object is received
        queue_item = queue.pop
        break if queue_item.nil?

        appname, appconfig = queue_item
        output_lines = [colorize_green("================== #{appname} ==================")]

        # Check if dev-env-config exists, and if so pull the dev-env configuration. Otherwise clone it.
        output_lines += update_or_clone(appconfig, root_loc, appname)

        output_mutex.synchronize do
          output_lines.each { |line| puts line }
        end
      end
    end
  end

  populate_queue(config, queue)
  threads.map(&:join)
end

def populate_queue(config, queue)
  # Put an item representing each app onto the queue
  config['applications'].each do |appname, appconfig|
    queue.push [appname, appconfig]
  end

  # Put enough nil objects onto the queue to ensure all the threads shut down once they have processed all the apps
  THREAD_COUNT.times do
    queue.push nil
  end
end

def required_ref(appconfig)
  # Ref is the key we check first, but then branch for backwards compatibility
  appconfig.fetch('ref', appconfig['branch'])
end

def update_or_clone(appconfig, root_loc, appname)
  output = if Dir.exist?("#{root_loc}/apps/#{appname}")
             update_app(appconfig, root_loc, appname)
           else
             clone_app(appconfig, root_loc, appname)
           end

  # Attempt to merge our remote branch into our local branch, if it's straightforward
  output += merge(root_loc, appname, required_ref(appconfig))
  output
end

def current_branch(root_loc, appname)
  # What branch are we working on?
  current_branch = `git -C #{root_loc}/apps/#{appname} rev-parse --abbrev-ref HEAD`.strip
  # Check for a detached head scenario (i.e. a specific commit) - technically there is therefore no branch
  current_branch = 'detached' if current_branch.eql? 'HEAD'
  current_branch
end

def merge(root_loc, appname, required_branch)
  return [] if current_branch(root_loc, appname) == 'detached'

  output_lines = [colorize_lightblue("Bringing #{required_branch} up to date")]
  if run_command("git -C #{root_loc}/apps/#{appname} merge --ff-only", output_lines) != 0
    output_lines << colorize_yellow("The local branch couldn't be fast forwarded (a merge is probably " \
                                    "required), so to be safe I didn't update anything")
  end
  output_lines
end

def update_app(appconfig, root_loc, appname)
  output_lines = []
  output_lines << colorize_lightblue(
    'The repo directory for this app already exists, so I will try to update it'
  )

  current_branch = current_branch(root_loc, appname)

  # If the configuration specifies a fixed commit leave them be
  if current_branch == 'detached'
    output_lines << colorize_yellow('Detached head detected, nothing to update')
    return output_lines
  end

  # Or the user is not working in the branch originally checked out...
  required_reference = required_ref(appconfig)
  unless current_branch.eql? required_reference
    output_lines << colorize_yellow("The current branch (#{current_branch}) differs from the devenv " \
                                    "configuration (#{required_reference}) so I'm not going to update anything")
    return output_lines
  end

  # Update all the remote branches (this will not change the local branch, we'll do that further down')
  output_lines << colorize_lightblue('Fetching from remote...')
  return output_lines unless run_command('git -C ' + "#{root_loc}/apps/#{appname} fetch origin", output_lines) != 0

  # If there is a git error we shouldn't continue
  output_lines << colorize_red("Error while updating #{appname}")
  output_lines << colorize_yellow('Continuing in 3 seconds...')
  sleep(3)
  output_lines
end

def clone_app(appconfig, root_loc, appname)
  output_lines = []
  output_lines << colorize_lightblue("#{appname} does not yet exist, so I will clone it")
  repo = appconfig['repo']
  if run_command("git clone #{repo} #{root_loc}/apps/#{appname}", output_lines) != 0
    # If there is a git error we shouldn't continue
    output_lines << colorize_red("Error while cloning #{appname}")
    output_lines << colorize_yellow('Continuing in 3 seconds...')
    sleep(3)
  end
  # What branch are we working on?
  current_branch = current_branch(root_loc, appname)

  # If we have to, check out the branch/tag/commit that the config wants us to use
  required_reference = required_ref(appconfig)
  if !current_branch.eql? required_reference
    output_lines << colorize_lightblue("Switching to #{required_reference}")
    run_command("git -C #{root_loc}/apps/#{appname} checkout #{required_reference}", output_lines)
  else
    output_lines << colorize_lightblue("Current branch is already #{current_branch}")
  end
  output_lines
end

update_apps(File.dirname(__FILE__) + '../../') if $PROGRAM_NAME == __FILE__
