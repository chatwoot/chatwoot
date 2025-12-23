# frozen_string_literal: true

require 'delegate'
require 'shellwords'

class Pry
  # The super-class of all commands, new commands should be created by calling
  # {Pry::CommandSet#command} which creates a BlockCommand or
  # {Pry::CommandSet#create_command} which creates a ClassCommand. Please don't
  # use this class directly.
  class Command
    extend Helpers::DocumentationHelpers
    extend CodeObject::Helpers

    include Pry::Helpers::BaseHelpers
    include Pry::Helpers::CommandHelpers
    include Pry::Helpers::Text

    # represents a void return value for a command
    VOID_VALUE = Object.new

    # give it a nice inspect
    def VOID_VALUE.inspect
      "void"
    end

    # Properties of the command itself (as passed as arguments to
    # {CommandSet#command} or {CommandSet#create_command}).
    class << self
      attr_writer :block
      attr_writer :description
      attr_writer :command_options
      attr_writer :match

      def match(arg = nil)
        if arg
          @command_options ||= default_options(arg)
          @command_options[:listing] = arg.is_a?(String) ? arg : arg.inspect
          @match = arg
        end
        @match ||= nil
      end

      # Define or get the command's description
      def description(arg = nil)
        @description = arg if arg
        @description ||= nil
      end

      # Define or get the command's options
      def command_options(arg = nil)
        @command_options ||= default_options(match)
        @command_options.merge!(arg) if arg
        @command_options
      end
      # backward compatibility
      alias options command_options
      alias options= command_options=

      # Define or get the command's banner
      def banner(arg = nil)
        @banner = arg if arg
        @banner ||= description
      end

      def block
        @block || instance_method(:process)
      end

      def source
        file, line = block.source_location
        strip_leading_whitespace(Pry::Code.from_file(file).expression_at(line))
      end

      def doc
        new.help
      end

      def source_file
        Array(block.source_location).first
      end
      alias file source_file

      def source_line
        Array(block.source_location).last
      end
      alias line source_line

      def default_options(match)
        {
          keep_retval: false,
          argument_required: false,
          interpolate: true,
          shellwords: true,
          listing: (match.is_a?(String) ? match : match.inspect),
          use_prefix: true,
          takes_block: false
        }
      end

      def name
        super.to_s == "" ? "#<class(Pry::Command #{match.inspect})>" : super
      end

      def inspect
        name
      end

      def command_name
        options[:listing]
      end

      # Create a new command with the given properties.
      # @param [String, Regex] match The thing that triggers this command
      # @param [String] description The description to appear in `help`
      # @param [Hash] options Behavioral options (see {Pry::CommandSet#command})
      # @param [Module] helpers A module of helper functions to be included.
      # @yield optional, used for BlockCommands
      # @return [Class] (a subclass of {Pry::Command})
      def subclass(match, description, options, helpers, &block)
        klass = Class.new(self)
        klass.send(:include, helpers)
        klass.match = match
        klass.description = description
        klass.command_options = options
        klass.block = block
        klass
      end

      # Should this command be called for the given line?
      # @param [String] val A line input at the REPL
      # @return [Boolean]
      def matches?(val)
        command_regex =~ val
      end

      # How well does this command match the given line?
      #
      # Higher scores are better because they imply that this command matches
      # the line more closely.
      #
      # The score is calculated by taking the number of characters at the start
      # of the string that are used only to identify the command, not as part of
      # the arguments.
      #
      # @example
      #   /\.(.*)/.match_score(".foo") #=> 1
      #   /\.*(.*)/.match_score("...foo") #=> 3
      #   'hi'.match_score("hi there") #=> 2
      #
      # @param [String] val A line input at the REPL
      # @return [Fixnum]
      def match_score(val)
        if command_regex =~ val
          if Regexp.last_match.size > 1
            Regexp.last_match.begin(1)
          else
            Regexp.last_match.end(0)
          end
        else
          -1
        end
      end

      def command_regex
        prefix = convert_to_regex(Pry.config.command_prefix)
        prefix = "(?:#{prefix})?" unless options[:use_prefix]

        /\A#{prefix}#{convert_to_regex(match)}(?!\S)/
      end

      def convert_to_regex(obj)
        case obj
        when String
          Regexp.escape(obj)
        else
          obj
        end
      end

      # The group in which the command should be displayed in "help" output.
      # This is usually auto-generated from directory naming, but it can be
      # manually overridden if necessary.
      # Group should not be changed once it is initialized.
      def group(name = nil)
        @group ||= begin
          name || case Pry::Method(block).source_file
                  when %r{/pry/.*_commands/(.*).rb}
                    Regexp.last_match(1).capitalize.tr('_', " ")
                  when /(pry-\w+)-([\d\.]+([\w\.]+)?)/
                    name = Regexp.last_match(1)
                    version = Regexp.last_match(2)
                    "#{name} (v#{version})"
                  when /pryrc/
                    "pryrc"
                  else
                    "(other)"
                  end
        end
      end

      def state
        Pry::CommandState.default.state_for(match)
      end
    end

    # Properties of one execution of a command (passed by {Pry#run_command} as a hash of
    # context and expanded in `#initialize`
    attr_accessor :output
    attr_accessor :target
    attr_accessor :captures
    attr_accessor :eval_string
    attr_accessor :arg_string
    attr_accessor :context
    attr_accessor :command_set
    attr_accessor :hooks
    attr_accessor :pry_instance
    alias _pry_= pry_instance=

    # The block we pass *into* a command so long as `:takes_block` is
    # not equal to `false`
    # @example
    #   my-command | do
    #     puts "block content"
    #   end
    attr_accessor :command_block

    # Instantiate a command, in preparation for calling it.
    # @param [Hash] context The runtime context to use with this command.
    def initialize(context = {})
      self.context      = context
      self.target       = context[:target]
      self.output       = context[:output]
      self.eval_string  = context[:eval_string]
      self.command_set  = context[:command_set]
      self.hooks        = context[:hooks]
      self.pry_instance = context[:pry_instance]
    end

    # Make those properties accessible to instances
    def name
      self.class.name
    end

    def match
      self.class.match
    end

    def description
      self.class.description
    end

    def block
      self.class.block
    end

    def command_options
      self.class.options
    end

    def command_name
      self.class.command_name
    end

    def source
      self.class.source
    end

    # Run a command from another command.
    # @param [String] command_string The string that invokes the command
    # @param [Array] args Further arguments to pass to the command
    # @example
    #   run "show-input"
    # @example
    #   run ".ls"
    # @example
    #   run "amend-line",  "5", 'puts "hello world"'
    def run(command_string, *args)
      command_string = pry_instance.config.command_prefix.to_s + command_string
      complete_string = "#{command_string} #{args.join(' ')}".rstrip
      command_set.process_line(complete_string, context)
    end

    def commands
      command_set.to_hash
    end

    def void
      VOID_VALUE
    end

    def _pry_
      Pry::Warning.warn('_pry_ is deprecated, use pry_instance instead')
      pry_instance
    end

    # @return [Object] The value of `self` inside the `target` binding.
    def target_self
      target.eval('self')
    end

    # @return [Hash] Pry commands can store arbitrary state
    #   here. This state persists between subsequent command invocations.
    #   All state saved here is unique to the command, it does not
    #   need to be namespaced.
    # @example
    #   state.my_state = "my state"  # this will not conflict with any
    #                                # `state.my_state` used in another command.
    def state
      self.class.state
    end

    # Revaluate the string (str) and perform interpolation.
    # @param [String] str The string to reevaluate with interpolation.
    #
    # @return [String] The reevaluated string with interpolations
    #   applied (if any).
    def interpolate_string(str)
      dumped_str = str.dump
      if dumped_str.gsub!(/\\\#\{/, '#{')
        target.eval(dumped_str)
      else
        str
      end
    end

    # Display a warning if a command collides with a local/method in
    # the current scope.
    def check_for_command_collision(command_match, arg_string)
      collision_type = target.eval("defined?(#{command_match})")
      collision_type ||= 'local-variable' if arg_string =~ %r{\A\s*[-+*/%&|^]*=}

      if collision_type
        output.puts(
          "#{Helpers::Text.bold('WARNING:')} Calling Pry command '#{command_match}', " \
          "which conflicts with a #{collision_type}.\n\n"
        )
      end
    rescue Pry::RescuableException # rubocop:disable Lint/HandleExceptions
    end

    # Extract necessary information from a line that Command.matches? this
    # command.
    #
    # Returns an array of four elements:
    #
    # ```
    #  [String] the portion of the line that matched with the Command match
    #  [String] a string of all the arguments (i.e. everything but the match)
    #  [Array]  the captures caught by the command_regex
    #  [Array]  the arguments obtained by splitting the arg_string
    # ```
    #
    # @param [String] val The line of input
    # @return [Array]
    def tokenize(val)
      val = interpolate_string(val) if command_options[:interpolate]

      self.class.command_regex =~ val

      # please call Command.matches? before Command#call_safely
      unless Regexp.last_match
        raise CommandError, "fatal: called a command which didn't match?!"
      end

      captures = Regexp.last_match.captures
      pos = Regexp.last_match.end(0)

      arg_string = val[pos..-1]

      # remove the one leading space if it exists
      arg_string.slice!(0) if arg_string.start_with?(" ")

      # process and pass a block if one is found
      pass_block(arg_string) if command_options[:takes_block]

      args =
        if arg_string
          if command_options[:shellwords]
            Shellwords.shellwords(arg_string)
          else
            arg_string.split(" ")
          end
        else
          []
        end

      [val[0..pos].rstrip, arg_string, captures, args]
    end

    # Process a line that Command.matches? this command.
    # @param [String] line The line to process
    # @return [Object, Command::VOID_VALUE]
    def process_line(line)
      command_match, arg_string, captures, args = tokenize(line)

      if Pry.config.collision_warning
        check_for_command_collision(command_match, arg_string)
      end

      self.arg_string = arg_string
      self.captures = captures

      call_safely(*(captures + args))
    end

    # Generate completions for this command
    #
    # @param [String] _search The line typed so far
    # @return [Array<String>]  Completion words
    def complete(_search)
      []
    end

    private

    # Run the command with the given `args`.
    #
    # This is a public wrapper around `#call` which ensures all preconditions
    # are met.
    #
    # @param [Array<String>] args The arguments to pass to this command.
    # @return [Object] The return value of the `#call` method, or
    #   {Command::VOID_VALUE}.
    def call_safely(*args)
      if command_options[:argument_required] && args.empty?
        raise CommandError, "The command '#{command_name}' requires an argument."
      end

      ret = use_unpatched_symbol do
        call_with_hooks(*args)
      end
      command_options[:keep_retval] ? ret : void
    end

    def use_unpatched_symbol
      call_method = Symbol.method_defined?(:call) && Symbol.instance_method(:call)
      Symbol.class_eval { undef :call } if call_method
      yield
    ensure
      Symbol.instance_eval { define_method(:call, call_method) } if call_method
    end

    # Pass a block argument to a command.
    # @param [String] arg_string The arguments (as a string) passed to the command.
    #   We inspect these for a '| do' or a '| {' and if we find it we use it
    #   to start a block input sequence. Once we have a complete
    #   block, we save it to an accessor that can be retrieved from the command context.
    #   Note that if we find the '| do' or '| {' we delete this and the
    #   elements following it from `arg_string`.
    def pass_block(arg_string)
      # Workaround for weird JRuby bug where rindex in this case can return nil
      # even when there's a match.
      arg_string.scan(/\| *(?:do|\{)/)
      block_index = $LAST_MATCH_INFO && $LAST_MATCH_INFO.offset(0)[0]

      return unless block_index

      block_init_string = arg_string.slice!(block_index..-1)[1..-1]
      prime_string = "proc #{block_init_string}\n"

      block_string =
        if !Pry::Code.complete_expression?(prime_string)
          pry_instance.r(target, prime_string)
        else
          prime_string
        end

      begin
        self.command_block = target.eval(block_string)
      rescue Pry::RescuableException
        raise CommandError, "Incomplete block definition."
      end
    end

    def find_hooks(event)
      event_name = "#{event}_#{command_name}"
      (hooks || Pry.hooks || self.class.hooks).get_hooks(event_name).values
    end

    def before_hooks
      find_hooks('before')
    end

    def after_hooks
      find_hooks('after')
    end

    # Run the `#call` method and all the registered hooks.
    # @param [Array<String>] args The arguments to `#call`
    # @return [Object] The return value from `#call`
    def call_with_hooks(*args)
      before_hooks.each { |block| instance_exec(*args, &block) }

      ret = call(*args)

      after_hooks.each do |block|
        ret = instance_exec(*args, &block)
      end

      ret
    end

    # Normalize method arguments according to its arity.
    #
    # @param [Integer] method
    # @param [Array] args
    # @return [Array] a (possibly shorter) array of the arguments to pass
    def normalize_method_args(method, args)
      case method.arity
      when -1
        args
      when 0
        []
      else
        args.values_at(*(0..(method.arity - 1)).to_a)
      end
    end
  end
end
