# frozen_string_literal: true

require 'ostruct'

class Pry
  # @api private
  class Config
    extend Attributable

    # @return [IO, #readline] he object from which Pry retrieves its lines of
    #   input
    attribute :input

    # @return [IO, #puts] where Pry should output results provided by {input}
    attribute :output

    # @return [Pry::CommandSet]
    attribute :commands

    # @return [Proc] the printer for Ruby expressions (not commands)
    attribute :print

    # @return [Proc] the printer for exceptions
    attribute :exception_handler

    # @return [Array] Exception that Pry shouldn't rescue
    attribute :unrescued_exceptions

    # @deprecated
    # @return [Array] Exception that Pry shouldn't rescue
    attribute :exception_whitelist

    # @return [Integer] The number of lines of context to show before and after
    #   exceptions
    attribute :default_window_size

    # @return [Pry::Hooks]
    attribute :hooks

    # @return [Pry::Prompt]
    attribute :prompt

    # @return [String] The display name that is part of the prompt
    attribute :prompt_name

    # @return [Array<Object>] the list of objects that are known to have a
    #   1-line #inspect output suitable for prompt
    attribute :prompt_safe_contexts

    # If it is a String, then that String is used as the shell
    # command to invoke the editor.
    #
    # If it responds to #call is callable then `file`, `line`, and `reloading`
    # are passed to it. `reloading` indicates whether Pry will be reloading code
    # after the shell command returns. All parameters are optional.
    # @return [String, #call]
    attribute :editor

    # A string that must precede all commands. For example, if is is
    # set to "%", the "cd" command must be invoked as "%cd").
    # @return [String]
    attribute :command_prefix

    # @return [Boolean]
    attribute :color

    # @return [Boolean]
    attribute :pager

    # @return [Boolean] whether the global ~/.pryrc should be loaded
    attribute :should_load_rc

    # @return [Boolean] whether the local ./.pryrc should be loaded
    attribute :should_load_local_rc

    # @return [Boolean] whether to load files specified with the -r flag
    attribute :should_load_requires

    # @return [Boolean] whether to disable edit-method's auto-reloading behavior
    attribute :disable_auto_reload

    # Whether Pry should trap SIGINT and cause it to raise an Interrupt
    # exception. This is only useful on JRuby, MRI does this for us.
    # @return [Boolean]
    attribute :should_trap_interrupts

    # @return [Pry::History]
    attribute :history

    # @return [Boolean]
    attribute :history_save

    # @return [Boolean]
    attribute :history_load

    # @return [String]
    attribute :history_file

    # @return [Array<String,Regexp>]
    attribute :history_ignorelist

    # @return [Array<String>] Ruby files to be required
    attribute :requires

    # @return [Integer] how many input/output lines to keep in memory
    attribute :memory_size

    # @return [Proc] The proc that runs system commands
    attribute :system

    # @return [Boolean]
    attribute :auto_indent

    # @return [Boolean]
    attribute :correct_indent

    # @return [Boolean] whether or not display a warning when a command name
    #   collides with a method/local in the current context.
    attribute :collision_warning

    # @return [Hash{Symbol=>Proc}]
    attribute :extra_sticky_locals

    # @return [#build_completion_proc] a completer to use
    attribute :completer

    # @return [Boolean] suppresses whereami output on `binding.pry`
    attribute :quiet

    # @return [Boolean] displays a warning about experience improvement on
    #   Windows
    attribute :windows_console_warning

    # @return [Proc]
    attribute :command_completions

    # @return [Proc]
    attribute :file_completions

    # @return [Hash]
    attribute :ls

    # @return [String] a line of code to execute in context before the session
    #   starts
    attribute :exec_string

    # @return [String]
    attribute :output_prefix

    # @return [String]
    # @since v0.13.0
    attribute :rc_file

    def initialize
      merge!(
        input: MemoizedValue.new { lazy_readline },
        output: $stdout.tap { |out| out.sync = true },
        commands: Pry::Commands,
        prompt_name: 'pry',
        prompt: Pry::Prompt[:default],
        prompt_safe_contexts: [String, Numeric, Symbol, nil, true, false],
        print: Pry::ColorPrinter.method(:default),
        quiet: false,
        exception_handler: Pry::ExceptionHandler.method(:handle_exception),

        unrescued_exceptions: [
          ::SystemExit, ::SignalException, Pry::TooSafeException
        ],

        exception_whitelist: MemoizedValue.new do
          output.puts(
            '[warning] Pry.config.exception_whitelist is deprecated, ' \
            'please use Pry.config.unrescued_exceptions instead.'
          )
          unrescued_exceptions
        end,

        hooks: Pry::Hooks.default,
        pager: true,
        system: Pry::SystemCommandHandler.method(:default),
        color: Pry::Helpers::BaseHelpers.use_ansi_codes?,
        default_window_size: 5,
        editor: Pry::Editor.default,
        rc_file: default_rc_file,
        should_load_rc: true,
        should_load_local_rc: true,
        should_trap_interrupts: Pry::Helpers::Platform.jruby?,
        disable_auto_reload: false,
        command_prefix: '',
        auto_indent: Pry::Helpers::BaseHelpers.use_ansi_codes?,
        correct_indent: true,
        collision_warning: false,
        output_prefix: '=> ',
        requires: [],
        should_load_requires: true,
        windows_console_warning: true,
        control_d_handler: Pry::ControlDHandler.method(:default),
        memory_size: 100,
        extra_sticky_locals: {},
        command_completions: proc { commands.keys },
        file_completions: proc { Dir['.'] },
        ls: OpenStruct.new(Pry::Command::Ls::DEFAULT_OPTIONS),
        completer: Pry::InputCompleter,
        history_save: true,
        history_load: true,
        history_file: Pry::History.default_file,
        history_ignorelist: [],
        history: MemoizedValue.new do
          if defined?(input::HISTORY)
            Pry::History.new(history: input::HISTORY)
          else
            Pry::History.new
          end
        end,
        exec_string: ''
      )

      @custom_attrs = {}
    end

    def merge!(config_hash)
      config_hash.each_pair { |attr, value| __send__("#{attr}=", value) }
      self
    end

    def merge(config_hash)
      dup.merge!(config_hash)
    end

    def []=(attr, value)
      @custom_attrs[attr.to_s] = Config::Value.new(value)
    end

    def [](attr)
      @custom_attrs[attr.to_s].call
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(method_name, *args, &_block)
      name = method_name.to_s

      if name.end_with?('=')
        self[name[0..-2]] = args.first
      elsif @custom_attrs.key?(name)
        self[name]
      end
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(method_name, include_all = false)
      @custom_attrs.key?(method_name.to_s.tr('=', '')) || super
    end

    def initialize_dup(other)
      super
      @custom_attrs = @custom_attrs.dup
    end

    attr_reader :control_d_handler
    def control_d_handler=(value)
      proxy_proc =
        if value.arity == 2
          Pry::Warning.warn(
            "control_d_handler's arity of 2 parameters was deprecated " \
            '(eval_string, pry_instance). Now it gets passed just 1 ' \
            'parameter (pry_instance)'
          )
          proc do |*args|
            if args.size == 2
              value.call(args.first, args[1])
            else
              value.call(args.first.eval_string, args.first)
            end
          end
        else
          proc do |*args|
            if args.size == 2
              value.call(args[1])
            else
              value.call(args.first)
            end
          end
        end
      @control_d_handler = proxy_proc
    end

    private

    def lazy_readline
      require 'readline'
      ::Readline
    rescue LoadError
      output.puts(
        "Sorry, you can't use Pry without Readline or a compatible library. \n" \
        "Possible solutions: \n" \
        " * Rebuild Ruby with Readline support using `--with-readline` \n" \
        " * Use the rb-readline gem, which is a pure-Ruby port of Readline \n" \
        " * Use the pry-coolline gem, a pure-ruby alternative to Readline"
      )
      raise
    end

    def default_rc_file
      [Pry::Env['PRYRC'],
       # See XDG Base Directory Specification at
       # https://specifications.freedesktop.org/basedir-spec/latest/
       "#{Pry::Env['XDG_CONFIG_HOME']}/pry/pryrc",
       File.expand_path('~/.pryrc'),
       File.expand_path('~/.config/pry/pryrc')]
        .compact
        .find { |file| File.exist?(file) }
    end
  end
end
