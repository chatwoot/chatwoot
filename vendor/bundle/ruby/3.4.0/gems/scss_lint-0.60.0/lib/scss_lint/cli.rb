require 'scss_lint/options'

module SCSSLint
  # Responsible for parsing command-line options and executing the appropriate
  # application logic based on the options specified.
  class CLI
    attr_reader :config, :options

    # Subset of semantic exit codes conforming to `sysexits` documentation.
    EXIT_CODES = {
      ok:             0,
      warning:        1,  # One or more warnings (but no errors) were reported
      error:          2,  # One or more errors were reported
      usage:          64, # Command line usage error
      no_input:       66, # Input file did not exist or was not readable
      unavailable:    69, # Required library is unavailable
      software:       70, # Internal software error
      config:         78, # Configuration error
      no_files:       80, # No files matched by specified glob patterns
      plugin:         82, # Plugin loading error
      preprocessor:   84, # Preprocessor error
    }.freeze

    # Create a CLI that outputs to the specified logger.
    #
    # @param logger [SCSSLint::Logger]
    def initialize(logger)
      @log = logger
    end

    def run(args)
      options = SCSSLint::Options.new.parse(args)
      act_on_options(options)
    rescue StandardError => e
      handle_runtime_exception(e, options)
    end

  private

    attr_reader :log

    def act_on_options(options)
      log.color_enabled = options.fetch(:color, log.tty?)
      load_required_paths(options)
      load_reporters(options)

      if options[:help]
        print_help(options)
      elsif options[:version]
        print_version
      elsif options[:show_formatters]
        print_formatters
      else
        config = setup_configuration(options)

        if options[:show_linters]
          print_linters
        else
          scan_for_lints(options, config)
        end
      end
    end

    def scan_for_lints(options, config)
      runner = Runner.new(config)
      files = files_to_lint(options, config)
      runner.run(files)
      report_lints(options, runner.lints, files)

      if runner.lints.any?(&:error?)
        halt :error
      elsif runner.lints.any?
        halt :warning
      else
        halt :ok
      end
    end

    def files_to_lint(options, config)
      if options[:stdin_file_path]
        [{ file: STDIN, path: options[:stdin_file_path] }]
      else
        patterns = Array(options[:files]).any? ? Array(options[:files]) : config.scss_files
        FileFinder.new(config).find(patterns).map do |file_path|
          { path: file_path }
        end
      end
    end

    def handle_runtime_exception(exception, options) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/LineLength, Metrics/MethodLength
      case exception
      when SCSSLint::Exceptions::InvalidCLIOption
        log.error exception.message
        log.info 'Run `scss-lint --help` for usage documentation'
        halt :usage
      when SCSSLint::Exceptions::InvalidConfiguration
        log.error exception.message
        halt :config
      when SCSSLint::Exceptions::RequiredLibraryMissingError
        log.error exception.message
        halt :unavailable
      when SCSSLint::Exceptions::NoFilesError
        log.error exception.message
        halt :no_files
      when SCSSLint::Exceptions::PluginGemLoadError
        log.error exception.message
        halt :plugin
      when Errno::ENOENT
        log.error exception.message
        halt :no_input
      when NoSuchLinter
        log.error exception.message
        halt :usage
      when SCSSLint::Exceptions::PreprocessorError
        log.error exception.message
        halt :preprocessor
      else
        config_file = relevant_configuration_file(options) if options

        log.bold_error exception.message
        log.error exception.backtrace.join("\n")
        log.warning 'Report this bug at ', false
        log.info BUG_REPORT_URL
        log.newline
        log.success 'To help fix this issue, please include:'
        log.log '- The above stack trace'
        log.log '- SCSS-Lint version: ', false
        log.info SCSSLint::VERSION
        log.log '- Sass version: ', false
        log.info Gem.loaded_specs['sass'].version.to_s
        log.log '- Ruby version: ', false
        log.info RUBY_VERSION
        if config_file
          log.log '- Contents of ', false
          log.info File.expand_path(config_file)
        end
        halt :software
      end
    end

    def setup_configuration(options)
      config_file = relevant_configuration_file(options)
      config = config_file ? Config.load(config_file) : Config.default
      merge_options_with_config(options, config)
    end

    # Return the path of the configuration file that should be loaded.
    #
    # @param options [Hash]
    # @return [String]
    def relevant_configuration_file(options)
      if options[:config_file]
        options[:config_file]
      elsif File.exist?(Config::FILE_NAME)
        Config::FILE_NAME
      elsif File.exist?(Config.user_file)
        Config.user_file
      end
    end

    # @param options [Hash]
    # @param config [Config]
    # @return [Config]
    def merge_options_with_config(options, config)
      if options[:excluded_files]
        options[:excluded_files].each do |file|
          config.exclude_file(file)
        end
      end

      if options[:included_linters]
        config.disable_all_linters
        LinterRegistry.extract_linters_from(options[:included_linters]).each do |linter|
          config.enable_linter(linter)
        end
      end

      if options[:excluded_linters]
        LinterRegistry.extract_linters_from(options[:excluded_linters]).each do |linter|
          config.disable_linter(linter)
        end
      end

      config
    end

    # @param options [Hash]
    # @param lints [Array<Lint>]
    # @param files [Array<Hash>]
    def report_lints(options, lints, files)
      sorted_lints = lints.sort_by { |l| [l.filename, l.location] }
      options.fetch(:reporters).each do |reporter, output|
        results = reporter.new(sorted_lints, files, log).report_lints
        next unless results

        if output == :stdout
          log.log results
        else
          File.new(output, 'w+').print results
        end
      end
    end

    def load_required_paths(options)
      Array(options[:required_paths]).each do |path|
        require path
      end
    rescue LoadError => e
      raise SCSSLint::Exceptions::RequiredLibraryMissingError,
            "Required library not found: #{e.message}"
    end

    def load_reporters(options)
      options[:reporters].map! do |reporter_name, output_file|
        begin
          reporter = SCSSLint::Reporter.const_get(reporter_name + 'Reporter')
        rescue NameError
          raise SCSSLint::Exceptions::InvalidCLIOption,
                "Invalid output format specified: #{reporter_name}"
        end
        [reporter, output_file]
      end
    end

    def print_formatters
      log.log 'Installed formatters:'

      reporter_names = SCSSLint::Reporter.descendants.map do |reporter|
        reporter.name.split('::').last.split('Reporter').first
      end

      reporter_names.sort.each do |reporter_name|
        log.log " - #{reporter_name}"
      end

      halt
    end

    def print_linters
      log.log 'Installed linters:'

      linter_names = LinterRegistry.linters.map(&:simple_name)

      linter_names.sort.each do |linter_name|
        log.log " - #{linter_name}"
      end

      halt
    end

    # @param options [Hash]
    def print_help(options)
      log.log options[:help]
      halt :ok
    end

    # @param options [Hash]
    def print_version
      log.log "scss-lint #{SCSSLint::VERSION}"
      halt :ok
    end

    # Used for ease-of testing
    # @param exit_status [Symbol]
    def halt(exit_status = :ok)
      EXIT_CODES[exit_status]
    end
  end
end
