require 'rake'
require 'rake/tasklib'

module SCSSLint
  # Rake task for scss-lint CLI.
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'scss_lint/rake_task'
  #   SCSSLint::RakeTask.new
  #
  #   # ...and then execute from the command line:
  #   rake scss_lint
  #
  # You can also specify the list of files as explicit task arguments:
  #
  # @example
  #   # Add the following to your Rakefile...
  #   require 'scss_lint/rake_task'
  #   SCSSLint::RakeTask.new
  #
  #   # ...and then execute from the command line (single quotes prevent shell
  #   # glob expansion and allow us to have a space after commas):
  #   rake 'scss_lint[app/assets/**/*.scss, other_files/**/*.scss]'
  class RakeTask < Rake::TaskLib
    # Name of the task.
    # @return [String]
    attr_accessor :name

    # Configuration file to use.
    # @return [String]
    attr_accessor :config

    # Command-line args to use.
    # @return [Array<String>]
    attr_accessor :args

    # List of files to lint (can contain shell globs).
    #
    # Note that this will be ignored if you explicitly pass a list of files as
    # task arguments via the command line or in the task definition.
    # @return [Array<String>]
    attr_accessor :files

    # Whether output from SCSS-lint should not be displayed to the standard out
    # stream.
    # @return [true,false]
    attr_accessor :quiet

    # Create the task so it is accessible via +Rake::Task['scss_lint']+.
    def initialize(name = :scss_lint)
      @name = name
      @files = []
      @quiet = false

      yield self if block_given?

      define
    end

  private

    def define
      # Generate a default description if one hasn't been provided
      desc default_description unless ::Rake.application.last_description

      task(name, [:files]) do |_task, task_args|
        # Lazy-load so task doesn't affect Rakefile load time
        require 'scss_lint'
        require 'scss_lint/cli'

        run_cli(task_args)
      end
    end

    def run_cli(task_args)
      cli_args = ['--config', config] if config

      logger = quiet ? SCSSLint::Logger.silent : SCSSLint::Logger.new(STDOUT)
      run_args = Array(cli_args) + Array(args) + files_to_lint(task_args)
      result = SCSSLint::CLI.new(logger).run(run_args)

      message =
        case result
        when CLI::EXIT_CODES[:error], CLI::EXIT_CODES[:warning]
          'scss-lint found one or more lints'
        when CLI::EXIT_CODES[:ok]
          'scss-lint found no lints'
        else
          'scss-lint failed with an error'
        end

      logger.log message
      exit result unless result == 0
    end

    def files_to_lint(task_args)
      # Note: we're abusing Rake's argument handling a bit here. We call the
      # first argument `files` but it's actually only the first file--we pull
      # the rest out of the `extras` from the task arguments. This is so we
      # can specify an arbitrary list of files separated by commas on the
      # command line or in a custom task definition.
      explicit_files = Array(task_args[:files]) + Array(task_args.extras)

      if explicit_files.any?
        explicit_files
      elsif files.any?
        files
      else
        [] # Will fall back to scss_files option if defined
      end
    end

    # Friendly description that shows the full command that will be executed.
    def default_description
      description = 'Run `scss-lint'
      description += " --config #{config}" if config
      description += " #{args}" if args
      description += " #{files.join(' ')}" if files.any?
      description += ' [files...]`'
      description
    end
  end
end
