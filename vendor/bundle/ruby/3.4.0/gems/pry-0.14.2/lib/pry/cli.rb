# frozen_string_literal: true

require 'stringio'

class Pry
  # Manage the processing of command line options
  class CLI
    NoOptionsError = Class.new(StandardError)

    class << self
      # @return [Proc] The Proc defining the valid command line options.
      attr_accessor :options

      # @return [Array] The Procs that process the parsed options. Plugins can
      #   utilize this facility in order to add and process their own Pry
      #   options.
      attr_accessor :option_processors

      # @return [Array<String>] The input array of strings to process
      #   as CLI options.
      attr_accessor :input_args

      # Add another set of CLI options (a Pry::Slop block)
      def add_options(&block)
        if options
          old_options = options
          self.options = proc do
            instance_exec(&old_options)
            instance_exec(&block)
          end
        else
          self.options = block
        end

        self
      end

      # Add a block responsible for processing parsed options.
      def add_option_processor(&block)
        self.option_processors ||= []
        option_processors << block

        self
      end

      # Clear `options` and `option_processors`
      def reset
        self.options           = nil
        self.option_processors = nil
      end

      def parse_options(args = ARGV)
        unless options
          raise NoOptionsError,
                "No command line options defined! Use Pry::CLI.add_options to " \
                "add command line options."
        end

        @pass_argv = args.index { |cli_arg| %w[- --].include?(cli_arg) }
        if @pass_argv
          slop_args = args[0...@pass_argv]
          self.input_args = args.replace(args[@pass_argv + 1..-1])
        else
          self.input_args = slop_args = args
        end

        begin
          opts = Pry::Slop.parse!(
            slop_args,
            help: true,
            multiple_switches: false,
            strict: true,
            &options
          )
        rescue Pry::Slop::InvalidOptionError
          # Display help message on unknown switches and exit.
          puts Pry::Slop.new(&options)
          Kernel.exit
        end

        Pry.initial_session_setup
        Pry.final_session_setup

        # Option processors are optional.
        option_processors.each { |processor| processor.call(opts) } if option_processors

        opts
      end

      def start(opts)
        Kernel.exit if opts.help?

        # invoked via cli
        Pry.cli = true

        # create the actual context
        if opts[:context]
          Pry.initial_session_setup
          context = Pry.binding_for(eval(opts[:context])) # rubocop:disable Security/Eval
          Pry.final_session_setup
        else
          context = Pry.toplevel_binding
        end

        if !@pass_argv && Pry::CLI.input_args.any? && Pry::CLI.input_args != ["pry"]
          full_name = File.expand_path(Pry::CLI.input_args.first)
          Pry.load_file_through_repl(full_name)
          Kernel.exit
        end

        # Start the session (running any code passed with -e, if there is any)
        Pry.start(context, input: StringIO.new(Pry.config.exec_string))
      end
    end

    reset
  end
end

# The default Pry command line options (before plugin options are included)
Pry::CLI.add_options do
  banner(
    "Usage: pry [OPTIONS]\n" \
    "Start a Pry session.\n" \
    "See http://pry.github.io/ for more information.\n" \
    "Copyright (c) 2016 John Mair (banisterfiend)" \
  )

  on(
    :e, :exec=, "A line of code to execute in context before the session starts"
  ) do |input|
    Pry.config.exec_string += "\n" unless Pry.config.exec_string.empty?
    Pry.config.exec_string += input
  end

  on "no-pager", "Disable pager for long output" do
    Pry.config.pager = false
  end

  on "no-history", "Disable history loading" do
    Pry.config.history_load = false
  end

  on "no-color", "Disable syntax highlighting for session" do
    Pry.config.color = false
  end

  on :f, "Suppress loading of pryrc" do
    Pry.config.should_load_rc = false
    Pry.config.should_load_local_rc = false
  end

  on :s, "select-plugin=", "Only load specified plugin (and no others)." do |_plugin_name|
    warn "The --select-plugin option is deprecated and has no effect"
  end

  on :d, "disable-plugin=", "Disable a specific plugin." do |_plugin_name|
    warn "The --disable-plugin option is deprecated and has no effect"
  end

  on "no-plugins", "Suppress loading of plugins." do
    warn "The --no-plugins option is deprecated and has no effect"
  end

  on "plugins", "List installed plugins." do
    warn "The --plugins option is deprecated and has no effect"
    warn "Try using `gem list pry-`"
    Kernel.exit
  end

  on "simple-prompt", "Enable simple prompt mode" do
    Pry.config.prompt = Pry::Prompt[:simple]
  end

  on "noprompt", "No prompt mode" do
    Pry.config.prompt = Pry::Prompt[:none]
  end

  on :r, :require=, "`require` a Ruby script at startup" do |file|
    Pry.config.requires << file
  end

  on(:I=, "Add a path to the $LOAD_PATH", as: Array, delimiter: ":") do |load_path|
    load_path.map! do |path|
      %r{\A\./} =~ path ? path : File.expand_path(path)
    end

    $LOAD_PATH.unshift(*load_path)
  end

  on "gem", "Shorthand for -I./lib -rgemname" do |_load_path|
    $LOAD_PATH.unshift("./lib")
    Dir["./lib/*.rb"].each do |file|
      Pry.config.requires << file
    end
  end

  on :v, :version, "Display the Pry version" do
    puts "Pry version #{Pry::VERSION} on Ruby #{RUBY_VERSION}"
    Kernel.exit
  end

  on :c, :context=,
     "Start the session in the specified context. Equivalent to " \
     "`context.pry` in a session.",
     default: "Pry.toplevel_binding"
end
