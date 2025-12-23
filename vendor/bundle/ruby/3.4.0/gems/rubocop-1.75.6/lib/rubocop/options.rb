# frozen_string_literal: true

require 'optparse'
require_relative 'arguments_env'
require_relative 'arguments_file'

module RuboCop
  class IncorrectCopNameError < StandardError; end

  class OptionArgumentError < StandardError; end

  # This class handles command line options.
  # @api private
  class Options
    E_STDIN_NO_PATH = '-s/--stdin requires exactly one path, relative to the ' \
                      'root of the project. RuboCop will use this path to determine which ' \
                      'cops are enabled (via eg. Include/Exclude), and so that certain cops ' \
                      'like Naming/FileName can be checked.'
    EXITING_OPTIONS = %i[version verbose_version show_cops show_docs_url lsp].freeze
    DEFAULT_MAXIMUM_EXCLUSION_ITEMS = 15

    def initialize
      @options = {}
      @validator = OptionsValidator.new(@options)
    end

    def parse(command_line_args)
      args_from_file = ArgumentsFile.read_as_arguments
      args_from_env = ArgumentsEnv.read_as_arguments
      args = args_from_file.concat(args_from_env).concat(command_line_args)

      define_options.parse!(args)

      @validator.validate_compatibility

      if @options[:stdin]
        # The parser will put the file name given after --stdin into
        # @options[:stdin]. If it did, then the args array should be empty.
        raise OptionArgumentError, E_STDIN_NO_PATH if args.any?

        # We want the STDIN contents in @options[:stdin] and the file name in
        # args to simplify the rest of the processing.
        args = [@options[:stdin]]
        @options[:stdin] = $stdin.binmode.read
      end

      [@options, args]
    end

    private

    # rubocop:disable Metrics/AbcSize
    def define_options
      OptionParser.new do |opts|
        opts.banner = rainbow.wrap('Usage: rubocop [options] [file1, file2, ...]').bright

        add_check_options(opts)
        add_cache_options(opts)
        add_lsp_option(opts)
        add_server_options(opts)
        add_output_options(opts)
        add_autocorrection_options(opts)
        add_config_generation_options(opts)
        add_additional_modes(opts)
        add_general_options(opts)

        # `stackprof` is not supported on JRuby and Windows.
        add_profile_options(opts) if RUBY_ENGINE == 'ruby' && !Platform.windows?
      end
    end
    # rubocop:enable Metrics/AbcSize

    def add_check_options(opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      section(opts, 'Basic Options') do # rubocop:disable Metrics/BlockLength
        option(opts, '-l', '--lint') do
          @options[:only] ||= []
          @options[:only] << 'Lint'
        end
        option(opts, '-x', '--fix-layout') do
          @options[:only] ||= []
          @options[:only] << 'Layout'
          @options[:autocorrect] = true
        end
        option(opts, '--safe')
        add_cop_selection_csv_option('except', opts)
        add_cop_selection_csv_option('only', opts)
        option(opts, '--only-guide-cops')
        option(opts, '-F', '--fail-fast')
        option(opts, '--disable-pending-cops')
        option(opts, '--enable-pending-cops')
        option(opts, '--ignore-disable-comments')
        option(opts, '--force-exclusion')
        option(opts, '--only-recognized-file-types')
        option(opts, '--ignore-parent-exclusion')
        option(opts, '--ignore-unrecognized-cops')
        option(opts, '--force-default-config')
        option(opts, '-s', '--stdin FILE')
        option(opts, '--editor-mode')
        option(opts, '-P', '--[no-]parallel')
        option(opts, '--raise-cop-error')
        add_severity_option(opts)
      end
    end

    def add_output_options(opts) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      section(opts, 'Output Options') do
        option(opts, '-f', '--format FORMATTER') do |key|
          @options[:formatters] ||= []
          @options[:formatters] << [key]
        end

        option(opts, '-D', '--[no-]display-cop-names')
        option(opts, '-E', '--extra-details')
        option(opts, '-S', '--display-style-guide')

        option(opts, '-o', '--out FILE') do |path|
          if @options[:formatters]
            @options[:formatters].last << path
          else
            @options[:output_path] = path
          end
        end

        option(opts, '--stderr')
        option(opts, '--display-time')
        option(opts, '--display-only-failed')
        option(opts, '--display-only-fail-level-offenses')
        option(opts, '--display-only-correctable')
        option(opts, '--display-only-safe-correctable')
      end
    end

    # rubocop:todo Naming/InclusiveLanguage
    # the autocorrect command-line arguments map to the autocorrect @options values like so:
    #                            :fix_layout  :autocorrect  :safe_autocorrect  :autocorrect_all
    # -x, --fix-layout           true         true          -                  -
    # -a, --auto-correct         -            true          true               -
    #     --safe-auto-correct    -            true          true               -
    # -A, --auto-correct-all     -            true          -                  true
    def add_autocorrection_options(opts) # rubocop:disable Metrics/MethodLength
      section(opts, 'Autocorrection') do
        option(opts, '-a', '--autocorrect') { @options[:safe_autocorrect] = true }
        option(opts, '--auto-correct') do
          handle_deprecated_option('--auto-correct', '--autocorrect')
          @options[:safe_autocorrect] = true
        end
        option(opts, '--safe-auto-correct') do
          handle_deprecated_option('--safe-auto-correct', '--autocorrect')
          @options[:safe_autocorrect] = true
        end

        option(opts, '-A', '--autocorrect-all') { @options[:autocorrect] = true }
        option(opts, '--auto-correct-all') do
          handle_deprecated_option('--auto-correct-all', '--autocorrect-all')
          @options[:autocorrect] = true
        end

        option(opts, '--disable-uncorrectable')
      end
    end
    # rubocop:enable Naming/InclusiveLanguage

    def add_config_generation_options(opts)
      section(opts, 'Config Generation') do
        option(opts, '--auto-gen-config')

        option(opts, '--regenerate-todo') do
          @options.replace(ConfigRegeneration.new.options.merge(@options))
        end

        option(opts, '--exclude-limit COUNT') { @validator.validate_exclude_limit_option }
        option(opts, '--no-exclude-limit')

        option(opts, '--[no-]offense-counts')
        option(opts, '--[no-]auto-gen-only-exclude')
        option(opts, '--[no-]auto-gen-timestamp')
        option(opts, '--[no-]auto-gen-enforced-style')
      end
    end

    def add_cop_selection_csv_option(option, opts)
      option(opts, "--#{option} [COP1,COP2,...]") do |list|
        unless list
          message = "--#{option} argument should be [COP1,COP2,...]."

          raise OptionArgumentError, message
        end

        cop_names = list.empty? ? [''] : list.split(',')
        cop_names.unshift('Lint/Syntax') if option == 'only' && !cop_names.include?('Lint/Syntax')

        @options[:"#{option}"] = cop_names
      end
    end

    def add_severity_option(opts)
      table = RuboCop::Cop::Severity::CODE_TABLE.merge(A: :autocorrect)
      option(opts, '--fail-level SEVERITY',
             RuboCop::Cop::Severity::NAMES + [:autocorrect],
             table) do |severity|
        @options[:fail_level] = severity
      end
    end

    def add_cache_options(opts)
      section(opts, 'Caching') do
        option(opts, '-C', '--cache FLAG')
        option(opts, '--cache-root DIR') { @validator.validate_cache_enabled_for_cache_root }
      end
    end

    def add_lsp_option(opts)
      section(opts, 'LSP Option') do
        option(opts, '--lsp')
      end
    end

    def add_server_options(opts)
      section(opts, 'Server Options') do
        option(opts, '--[no-]server')
        option(opts, '--restart-server')
        option(opts, '--start-server')
        option(opts, '--stop-server')
        option(opts, '--server-status')
        option(opts, '--no-detach')
      end
    end

    def add_additional_modes(opts)
      section(opts, 'Additional Modes') do
        option(opts, '-L', '--list-target-files')
        option(opts, '--show-cops [COP1,COP2,...]') do |list|
          @options[:show_cops] = list.nil? ? [] : list.split(',')
        end
        option(opts, '--show-docs-url [COP1,COP2,...]') do |list|
          @options[:show_docs_url] = list.nil? ? [] : list.split(',')
        end
      end
    end

    def add_general_options(opts)
      section(opts, 'General Options') do
        option(opts, '--init')
        option(opts, '-c', '--config FILE')
        option(opts, '-d', '--debug')
        option(opts, '--plugin FILE') { |f| plugin_feature(f) }
        option(opts, '-r', '--require FILE') { |f| require_feature(f) }
        option(opts, '--[no-]color')
        option(opts, '-v', '--version')
        option(opts, '-V', '--verbose-version')
      end
    end

    def add_profile_options(opts)
      section(opts, 'Profiling Options') do
        option(opts, '--profile') do
          @options[:profile] = true
          @options[:cache] = 'false' unless @options.key?(:cache)
        end
        option(opts, '--memory')
      end
    end

    def handle_deprecated_option(old_option, new_option)
      warn rainbow.wrap("#{old_option} is deprecated; use #{new_option} instead.").yellow
      @options[long_opt_symbol([new_option])] = @options.delete(long_opt_symbol([old_option]))
    end

    def rainbow
      @rainbow ||= begin
        rainbow = Rainbow.new
        rainbow.enabled = false if ARGV.include?('--no-color')
        rainbow
      end
    end

    # Creates a section of options in order to separate them visually when
    # using `--help`.
    def section(opts, heading, &_block)
      heading = rainbow.wrap(heading).bright
      opts.separator("\n#{heading}:\n")
      yield
    end

    # Sets a value in the @options hash, based on the given long option and its
    # value, in addition to calling the block if a block is given.
    def option(opts, *args)
      long_opt_symbol = long_opt_symbol(args)
      args += Array(OptionsHelp::TEXT[long_opt_symbol])
      opts.on(*args) do |arg|
        @options[long_opt_symbol] = arg
        yield arg if block_given?
      end
    end

    # Finds the option in `args` starting with -- and converts it to a symbol,
    # e.g. [..., '--autocorrect', ...] to :autocorrect.
    def long_opt_symbol(args)
      long_opt = args.find { |arg| arg.start_with?('--') }
      long_opt[2..].sub('[no-]', '').sub(/ .*/, '').tr('-', '_').gsub(/[\[\]]/, '').to_sym
    end

    def plugin_feature(file)
      # If any features were added on the CLI from `--plugin`,
      # add them to the config.
      ConfigLoaderResolver.new.resolve_plugins(Config.new, file)
    end

    def require_feature(file)
      if Plugin.plugin_capable?(file)
        # NOTE: Compatibility for before plugins style.
        warn Rainbow(<<~MESSAGE).yellow
          #{file} gem supports plugin, use `--plugin` instead of `--require`.
        MESSAGE
        plugin_feature(file)
      else
        # If any features were added on the CLI from `--require`,
        # add them to the config.
        require file
        ConfigLoader.add_loaded_features(file)
      end
    end
  end

  # Validates option arguments and the options' compatibility with each other.
  # @api private
  class OptionsValidator
    class << self
      SYNTAX_DEPARTMENTS = %w[Syntax Lint/Syntax].freeze
      private_constant :SYNTAX_DEPARTMENTS

      # Cop name validation must be done later than option parsing, so it's not
      # called from within Options.
      def validate_cop_list(names)
        return unless names

        cop_names = Cop::Registry.global.names
        departments = Cop::Registry.global.departments.map(&:to_s)

        names.each do |name|
          next if cop_names.include?(name)
          next if departments.include?(name)
          next if SYNTAX_DEPARTMENTS.include?(name)

          raise IncorrectCopNameError, format_message_from(name, cop_names)
        end
      end

      private

      def format_message_from(name, cop_names)
        message = 'Unrecognized cop or department: %<name>s.'
        message_with_candidate = "%<message>s\nDid you mean? %<candidate>s"
        corrections = NameSimilarity.find_similar_names(name, cop_names)

        if corrections.empty?
          format(message, name: name)
        else
          format(message_with_candidate, message: format(message, name: name),
                                         candidate: corrections.join(', '))
        end
      end
    end

    def initialize(options)
      @options = options
    end

    def validate_cop_options
      %i[only except].each { |opt| OptionsValidator.validate_cop_list(@options[opt]) }
    end

    # rubocop:disable Metrics/AbcSize
    def validate_compatibility # rubocop:disable Metrics/MethodLength
      if only_includes_redundant_disable?
        raise OptionArgumentError, 'Lint/RedundantCopDisableDirective cannot be used with --only.'
      end
      raise OptionArgumentError, 'Syntax checking cannot be turned off.' if except_syntax?
      unless boolean_or_empty_cache?
        raise OptionArgumentError, '-C/--cache argument must be true or false'
      end

      validate_auto_gen_config
      validate_autocorrect
      validate_display_only_failed
      validate_display_only_failed_and_display_only_correctable
      validate_display_only_correctable_and_autocorrect
      validate_lsp_and_editor_mode
      disable_parallel_when_invalid_option_combo

      return if incompatible_options.size <= 1

      raise OptionArgumentError, "Incompatible cli options: #{incompatible_options.inspect}"
    end
    # rubocop:enable Metrics/AbcSize

    def validate_auto_gen_config
      return if @options.key?(:auto_gen_config)

      message = '--%<flag>s can only be used together with --auto-gen-config.'

      %i[exclude_limit offense_counts auto_gen_timestamp
         auto_gen_only_exclude].each do |option|
        if @options.key?(option)
          raise OptionArgumentError, format(message, flag: option.to_s.tr('_', '-'))
        end
      end
    end

    def validate_display_only_failed
      return unless @options.key?(:display_only_failed)
      return if @options[:format] == 'junit'

      raise OptionArgumentError,
            '--display-only-failed can only be used together with --format junit.'
    end

    def validate_display_only_correctable_and_autocorrect
      return unless @options.key?(:autocorrect)
      return if !@options.key?(:display_only_correctable) &&
                !@options.key?(:display_only_safe_correctable)

      raise OptionArgumentError,
            '--autocorrect cannot be used with --display-only-[safe-]correctable.'
    end

    def validate_display_only_failed_and_display_only_correctable
      return unless @options.key?(:display_only_failed)
      return if !@options.key?(:display_only_correctable) &&
                !@options.key?(:display_only_safe_correctable)

      raise OptionArgumentError,
            '--display-only-failed cannot be used together with other display options.'
    end

    def validate_lsp_and_editor_mode
      return if !@options.key?(:lsp) || !@options.key?(:editor_mode)

      raise OptionArgumentError, 'Do not specify `--editor-mode` as it is redundant in `--lsp`.'
    end

    def validate_autocorrect
      if @options.key?(:safe_autocorrect) && @options.key?(:autocorrect_all)
        message = Rainbow(<<~MESSAGE).red
          Error: Both safe and unsafe autocorrect options are specified, use only one.
        MESSAGE
        raise OptionArgumentError, message
      end
      return if @options.key?(:autocorrect)
      return unless @options.key?(:disable_uncorrectable)

      raise OptionArgumentError,
            '--disable-uncorrectable can only be used together with --autocorrect.'
    end

    def disable_parallel_when_invalid_option_combo
      return unless @options.key?(:parallel)

      invalid_flags = invalid_arguments_for_parallel

      return if invalid_flags.empty?

      @options.delete(:parallel)

      puts '-P/--parallel is being ignored because ' \
           "it is not compatible with #{invalid_flags.join(', ')}."
    end

    def invalid_arguments_for_parallel
      [('--auto-gen-config' if @options.key?(:auto_gen_config)),
       ('-F/--fail-fast'    if @options.key?(:fail_fast)),
       ('--profile'         if @options[:profile]),
       ('--memory'          if @options[:memory]),
       ('--cache false'     if @options > { cache: 'false' })].compact
    end

    def only_includes_redundant_disable?
      @options.key?(:only) &&
        (@options[:only] & %w[Lint/RedundantCopDisableDirective RedundantCopDisableDirective]).any?
    end

    def except_syntax?
      @options.key?(:except) && (@options[:except] & %w[Lint/Syntax Syntax]).any?
    end

    def boolean_or_empty_cache?
      !@options.key?(:cache) || %w[true false].include?(@options[:cache])
    end

    def incompatible_options
      @incompatible_options ||= @options.keys & Options::EXITING_OPTIONS
    end

    def validate_exclude_limit_option
      return if /^\d+$/.match?(@options[:exclude_limit])

      # Emulate OptionParser's behavior to make failures consistent regardless
      # of option order.
      raise OptionParser::MissingArgument
    end

    def validate_cache_enabled_for_cache_root
      return unless @options[:cache] == 'false'

      raise OptionArgumentError, '--cache-root cannot be used with --cache false'
    end
  end

  # This module contains help texts for command line options.
  # @api private
  # rubocop:disable Metrics/ModuleLength
  module OptionsHelp
    MAX_EXCL = RuboCop::Options::DEFAULT_MAXIMUM_EXCLUSION_ITEMS.to_s
    FORMATTER_OPTION_LIST = RuboCop::Formatter::FormatterSet::BUILTIN_FORMATTERS_FOR_KEYS.keys

    TEXT = {
      only:                             'Run only the given cop(s).',
      only_guide_cops:                  ['Run only cops for rules that link to a',
                                         'style guide.'],
      except:                           'Exclude the given cop(s).',
      plugin:                           'Load a RuboCop plugin.',
      require:                          'Require Ruby file.',
      config:                           'Specify configuration file.',
      auto_gen_config:                  ['Generate a configuration file acting as a',
                                         'TODO list.'],
      regenerate_todo:                  ['Regenerate the TODO configuration file using',
                                         'the last configuration. If there is no existing',
                                         'TODO file, acts like --auto-gen-config.'],
      offense_counts:                   ['Include offense counts in configuration',
                                         'file generated by --auto-gen-config.',
                                         'Default is true.'],
      auto_gen_timestamp:
                                        ['Include the date and time when the --auto-gen-config',
                                         'was run in the file it generates. Default is true.'],
      auto_gen_enforced_style:
                                        ['Add a setting to the TODO configuration file to enforce',
                                         'the style used, rather than a per-file exclusion',
                                         'if one style is used in all files for cop with',
                                         'EnforcedStyle as a configurable option',
                                         'when the --auto-gen-config was run',
                                         'in the file it generates. Default is true.'],
      auto_gen_only_exclude:
                                        ['Generate only Exclude parameters and not Max',
                                         'when running --auto-gen-config, except if the',
                                         'number of files with offenses is bigger than',
                                         'exclude-limit. Default is false.'],
      exclude_limit:                    ['Set the limit for how many files to explicitly exclude.',
                                         'If there are more files than the limit, the cop will',
                                         "be disabled instead. Default is #{MAX_EXCL}."],
      disable_uncorrectable:            ['Used with --autocorrect to annotate any',
                                         'offenses that do not support autocorrect',
                                         'with `rubocop:todo` comments.'],
      no_exclude_limit:                 ['Do not set the limit for how many files to exclude.'],
      force_exclusion:                  ['Any files excluded by `Exclude` in configuration',
                                         'files will be excluded, even if given explicitly',
                                         'as arguments.'],
      only_recognized_file_types:       ['Inspect files given on the command line only if',
                                         'they are listed in `AllCops/Include` parameters',
                                         'of user configuration or default configuration.'],
      ignore_disable_comments:          ['Report offenses even if they have been manually disabled',
                                         'with a `rubocop:disable` or `rubocop:todo` directive.'],
      ignore_parent_exclusion:          ['Prevent from inheriting `AllCops/Exclude` from',
                                         'parent folders.'],
      ignore_unrecognized_cops:         ['Ignore unrecognized cops or departments in the config.'],
      force_default_config:             ['Use default configuration even if configuration',
                                         'files are present in the directory tree.'],
      format:                           ['Choose an output formatter. This option',
                                         'can be specified multiple times to enable',
                                         'multiple formatters at the same time.',
                                         *FORMATTER_OPTION_LIST.map do |item|
                                           "  #{item}#{' (default)' if item == '[p]rogress'}"
                                         end,
                                         '  custom formatter class name'],
      out:                              ['Write output to a file instead of STDOUT.',
                                         'This option applies to the previously',
                                         'specified --format, or the default format',
                                         'if no format is specified.'],
      fail_level:                       ['Minimum severity for exit with error code.',
                                         '  [A] autocorrect',
                                         '  [I] info',
                                         '  [R] refactor',
                                         '  [C] convention',
                                         '  [W] warning',
                                         '  [E] error',
                                         '  [F] fatal'],
      display_time:                     'Display elapsed time in seconds.',
      display_only_failed:              ['Only output offense messages. Omit passing',
                                         'cops. Only valid for --format junit.'],
      display_only_fail_level_offenses:
                                        ['Only output offense messages at',
                                         'the specified --fail-level or above.'],
      display_only_correctable:         ['Only output correctable offense messages.'],
      display_only_safe_correctable:    ['Only output safe-correctable offense messages',
                                         'when combined with --display-only-correctable.'],
      show_cops:                        ['Shows the given cops, or all cops by',
                                         'default, and their configurations for the',
                                         'current directory.',
                                         'You can use `*` as a wildcard.'],
      show_docs_url:                    ['Display url to documentation for the given',
                                         'cops, or base url by default.'],
      fail_fast:                        ['Inspect files in order of modification',
                                         'time and stop after the first file',
                                         'containing offenses.'],
      cache:                            ["Use result caching (FLAG=true) or don't",
                                         '(FLAG=false), default determined by',
                                         'configuration parameter AllCops: UseCache.'],
      cache_root:                       ['Set the cache root directory.',
                                         'Takes precedence over the configuration',
                                         'parameter AllCops: CacheRootDirectory and',
                                         'the $RUBOCOP_CACHE_ROOT environment variable.'],
      debug:                            'Display debug info.',
      display_cop_names:                ['Display cop names in offense messages.',
                                         'Default is true.'],
      disable_pending_cops:             'Run without pending cops.',
      display_style_guide:              'Display style guide URLs in offense messages.',
      enable_pending_cops:              'Run with pending cops.',
      extra_details:                    'Display extra details in offense messages.',
      lint:                             'Run only lint cops.',
      safe:                             'Run only safe cops.',
      stderr:                           ['Write all output to stderr except for the',
                                         'autocorrected source. This is especially useful',
                                         'when combined with --autocorrect and --stdin.'],
      list_target_files:                'List all files RuboCop will inspect.',
      autocorrect:                      'Autocorrect offenses (only when it\'s safe).',
      auto_correct:                     '(same, deprecated)',
      safe_auto_correct:                '(same, deprecated)',
      autocorrect_all:                  'Autocorrect offenses (safe and unsafe).',
      auto_correct_all:                 '(same, deprecated)',
      fix_layout:                       'Run only layout cops, with autocorrect on.',
      color:                            'Force color output on or off.',
      version:                          'Display version.',
      verbose_version:                  'Display verbose version.',
      parallel:                         ['Use available CPUs to execute inspection in',
                                         'parallel. Default is true.',
                                         'You can specify the number of parallel processes using',
                                         'the $PARALLEL_PROCESSOR_COUNT environment variable.'],
      stdin:                            ['Pipe source from STDIN, using FILE in offense',
                                         'reports. This is useful for editor integration.'],
      editor_mode:                      ['Optimize real-time feedback in editors,',
                                         'adjusting behaviors for editing experience.'],
      init:                             'Generate a .rubocop.yml file in the current directory.',
      server:                           ['If a server process has not been started yet, start',
                                         'the server process and execute inspection with server.',
                                         'Default is false.',
                                         'You can specify the server host and port with the',
                                         '$RUBOCOP_SERVER_HOST and the $RUBOCOP_SERVER_PORT',
                                         'environment variables.'],
      restart_server:                   'Restart server process.',
      start_server:                     'Start server process.',
      stop_server:                      'Stop server process.',
      server_status:                    'Show server status.',
      no_detach:                        'Run the server process in the foreground.',
      lsp:                              'Start a language server listening on STDIN.',
      raise_cop_error:                  ['Raise cop-related errors with cause and location.',
                                         'This is used to prevent cops from failing silently.',
                                         'Default is false.'],
      profile:                          'Profile rubocop.',
      memory:                           'Profile rubocop memory usage.'
    }.freeze
  end
  # rubocop:enable Metrics/ModuleLength
end
