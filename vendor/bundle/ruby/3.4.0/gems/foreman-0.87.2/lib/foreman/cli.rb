require "foreman"
require "foreman/helpers"
require "foreman/engine"
require "foreman/engine/cli"
require "foreman/export"
require "foreman/version"
require "shellwords"
require "yaml"
require "foreman/vendor/thor/lib/thor"

class Foreman::CLI < Foreman::Thor

  include Foreman::Helpers

  map ["-v", "--version"] => :version

  class_option :procfile, :type => :string, :aliases => "-f", :desc => "Default: Procfile"
  class_option :root,     :type => :string, :aliases => "-d", :desc => "Default: Procfile directory"

  desc "start [PROCESS]", "Start the application (or a specific PROCESS)"

  method_option :color,     :type => :boolean, :aliases => "-c", :desc => "Force color to be enabled"
  method_option :env,       :type => :string,  :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
  method_option :formation, :type => :string,  :aliases => "-m", :banner => '"alpha=5,bar=3"', :desc => 'Specify what processes will run and how many. Default: "all=1"'
  method_option :port,      :type => :numeric, :aliases => "-p"
  method_option :timeout,   :type => :numeric, :aliases => "-t", :desc => "Specify the amount of time (in seconds) processes have to shutdown gracefully before receiving a SIGKILL, defaults to 5."
  method_option :timestamp, :type => :boolean, :default => true, :desc => "Include timestamp in output"

  class << self
    # Hackery. Take the run method away from Thor so that we can redefine it.
    def is_thor_reserved_word?(word, type)
      return false if word == "run"
      super
    end
  end

  def start(process=nil)
    check_procfile!
    load_environment!
    engine.load_procfile(procfile)
    engine.options[:formation] = "#{process}=1" if process
    engine.start
  end

  desc "export FORMAT LOCATION", "Export the application to another process management format"

  method_option :app,         :type => :string,  :aliases => "-a"
  method_option :log,         :type => :string,  :aliases => "-l"
  method_option :run,         :type => :string,  :aliases => "-r", :desc => "Specify the pid file directory, defaults to /var/run/<application>"
  method_option :env,         :type => :string,  :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
  method_option :port,        :type => :numeric, :aliases => "-p"
  method_option :user,        :type => :string,  :aliases => "-u"
  method_option :template,    :type => :string,  :aliases => "-t"
  method_option :formation, :type => :string,  :aliases => "-m", :banner => '"alpha=5,bar=3"', :desc => 'Specify what processes will run and how many. Default: "all=1"'
  method_option :timeout,     :type => :numeric, :aliases => "-t", :desc => "Specify the amount of time (in seconds) processes have to shutdown gracefully before receiving a SIGKILL, defaults to 5."

  def export(format, location=nil)
    check_procfile!
    load_environment!
    engine.load_procfile(procfile)
    formatter = Foreman::Export.formatter(format)
    formatter.new(location, engine, options).export
  rescue Foreman::Export::Exception => ex
    error ex.message
  end

  desc "check", "Validate your application's Procfile"

  def check
    check_procfile!
    engine.load_procfile(procfile)
    error "no processes defined" unless engine.processes.length > 0
    puts "valid procfile detected (#{engine.process_names.join(', ')})"
  end

  desc "run COMMAND [ARGS...]", "Run a command using your application's environment"

  method_option :env, :type => :string, :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
  stop_on_unknown_option! :run

  def run(*args)
    load_environment!

    if File.file?(procfile)
      engine.load_procfile(procfile)
    end

    pid = fork do
      begin
        engine.env.each { |k,v| ENV[k] = v }
        if args.size == 1 && process = engine.process(args.first)
          process.exec(:env => engine.env)
        else
          exec args.shelljoin
        end
      rescue Errno::EACCES
        error "not executable: #{args.first}"
      rescue Errno::ENOENT
        error "command not found: #{args.first}"
      end
    end
    trap("INT") do
      Process.kill(:INT, pid)
    end
    Process.wait(pid)
    exit $?.exitstatus || 0
  rescue Interrupt
  end

  desc "version", "Display Foreman gem version"

  def version
    puts Foreman::VERSION
  end

  no_tasks do
    def engine
      @engine ||= begin
        engine_class = Foreman::Engine::CLI
        engine = engine_class.new(options)
        engine
      end
    end
  end

private ######################################################################

  def error(message)
    puts "ERROR: #{message}"
    exit 1
  end

  def check_procfile!
    error("#{procfile} does not exist.") unless File.file?(procfile)
  end

  def load_environment!
    if options[:env]
      options[:env].split(",").each do |file|
        engine.load_env file
      end
    else
      default_env = File.join(engine.root, ".env")
      engine.load_env default_env if File.file?(default_env)
    end
  end

  def procfile
    case
      when options[:procfile] then options[:procfile]
      when options[:root]     then File.expand_path(File.join(options[:root], "Procfile"))
      else "Procfile"
    end
  end

  def options
    original_options = super
    return original_options unless File.file?(".foreman")
    defaults = ::YAML::load_file(".foreman") || {}
    Foreman::Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
  end
end
