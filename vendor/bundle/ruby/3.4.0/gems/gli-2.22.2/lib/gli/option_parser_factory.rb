module GLI
  # Factory for creating an OptionParser based on app configuration and DSL calls
  class OptionParserFactory

    # Create an option parser factory for a command.  This has the added
    # feature of setting up -h and --help on the command if those
    # options aren't otherwise configured, e.g. to allow todo add --help as an
    # alternate to todo help add
    def self.for_command(command,accepts)
      self.new(command.flags,command.switches,accepts).tap { |factory|
        add_help_switches_to_command(factory.option_parser,command)
      }
    end

    # Create an OptionParserFactory for the given
    # flags, switches, and accepts
    def initialize(flags,switches,accepts)
      @flags = flags
      @switches = switches
      @options_hash = {}
      @option_parser = OptionParser.new do |opts|
        self.class.setup_accepts(opts,accepts)
        self.class.setup_options(opts,@switches,@options_hash)
        self.class.setup_options(opts,@flags,@options_hash)
      end
    end

    attr_reader :option_parser
    attr_reader :options_hash

    def options_hash_with_defaults_set!
      set_defaults(@flags,@options_hash)
      set_defaults(@switches,@options_hash)
      @options_hash
    end

  private

    def set_defaults(options_by_name,options_hash)
      options_by_name.values.each do |option|
        option.names_and_aliases.each do |option_name|
          [option_name,option_name.to_sym].each do |name|
            options_hash[name] = option.default_value if options_hash[name].nil?
          end
        end
      end
    end

    def self.setup_accepts(opts,accepts)
      accepts.each do |object,block|
        opts.accept(object) do |arg_as_string|
          block.call(arg_as_string)
        end
      end
    end

    def self.setup_options(opts,tokens,options)
      tokens.each do |ignore,token|
        opts.on(*token.arguments_for_option_parser) do |arg|
          token.names_and_aliases.each do |name|
            if token.kind_of?(Flag) && token.multiple?
              options[name] ||= []
              options[name.to_sym] ||= []
              options[name] << arg
              options[name.to_sym] << arg
            else
              options[name] = arg
              options[name.to_sym] = arg
            end
          end
        end
      end
    end

    def self.add_help_switches_to_command(option_parser,command)
      help_args = %w(-h --help).reject { |_| command.has_option?(_) }

      unless help_args.empty?
        help_args << "Get help for #{command.name}"
        option_parser.on(*help_args) do
          raise RequestHelp.new(command)
        end
      end
    end


  end
end
