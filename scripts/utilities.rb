def colorize_lightblue(str)
  "\e[36m#{str}\e[0m"
end

def colorize_red(str)
  "\e[31m#{str}\e[0m"
end

def colorize_yellow(str)
  "\e[33m#{str}\e[0m"
end

def colorize_green(str)
  "\e[32m#{str}\e[0m"
end

def colorize_pink(str)
  "\e[35m#{str}\e[0m"
end

# Runs a command in the nicest way, outputting to the console. Using system sometimes causes the console to stop
# outputting until a key is pressed.
def run_command(cmd, output_lines = nil, input_lines = nil)
  exitcode = -1
  Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
    # Anything to pipe in?
    unless input_lines.nil?
      stdin.puts(input_lines)
      stdin.close
    end
    stdout_and_stderr.each_line do |line|
      # Save the output lines for the caller if we have been given an array, else output immediately
      if output_lines.nil?
        puts line
      else
        output_lines << line
      end
    end
    exitcode = wait_thr.value.exitstatus
  end
  exitcode
end

def run_command_noshell(cmd, output_lines = nil, input_lines = nil)
  exitcode = -1
  Open3.popen2e(*cmd) do |stdin, stdout_and_stderr, wait_thr|
    # Anything to pipe in?
    unless input_lines.nil?
      stdin.puts(input_lines)
      stdin.close
    end
    stdout_and_stderr.each_line do |line|
      # Save the output lines for the caller if we have been given an array, else output immediately
      if output_lines.nil?
        puts line
      else
        output_lines << line
      end
    end
    exitcode = wait_thr.value.exitstatus
  end
  exitcode
end

def fail_and_exit(new_project)
  puts colorize_red('Something went wrong when cloning/pulling the dev-env configuration project. Check your URL?')
  # If we were cloning from a new URL, it is possible the URL was wrong - reset everything so they're asked again
  # next time
  if new_project
    File.delete(DEV_ENV_CONTEXT_FILE)
    FileUtils.rm_r DEV_ENV_CONFIG_DIR if Dir.exist?(DEV_ENV_CONFIG_DIR)
  end
  exit 1
end
