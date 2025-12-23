module GLI
  # An "option block" is a set of parseable options, starting from the beginning of
  # the argument list, stopping with the first unknown command-line element.
  # This class handles parsing that block
  class GLIOptionBlockParser

    # Create the parser using the given +OptionParser+ instance and exception handling
    # strategy.
    #
    # option_parser_factory:: An +OptionParserFactory+ instance, configured to parse wherever you are on the command line
    # exception_klass_or_block:: means of handling exceptions from +OptionParser+.  One of:
    #                            an exception class:: will be raised on errors with a message
    #                            lambda/block:: will be called with a single argument - the error message.
    def initialize(option_parser_factory,exception_klass_or_block)
      @option_parser_factory = option_parser_factory
      @extra_error_context = nil
      @exception_handler = if exception_klass_or_block.kind_of?(Class)
                             lambda { |message,extra_error_context|
                               raise exception_klass_or_block,message
                             }
                           else
                             exception_klass_or_block
                           end
    end

    # Parse the given argument list, returning the unparsed arguments and options hash of parsed arguments.
    # Exceptions from +OptionParser+ are given to the handler configured in the constructor
    #
    # args:: argument list.  This will be mutated
    #
    # Returns unparsed args
    def parse!(args)
      do_parse(args)
    rescue OptionParser::InvalidOption => ex
      @exception_handler.call("Unknown option #{ex.args.join(' ')}",@extra_error_context)
    rescue OptionParser::InvalidArgument => ex
      @exception_handler.call("#{ex.reason}: #{ex.args.join(' ')}",@extra_error_context)
    end

  protected

    def do_parse(args)
      first_non_option = nil
      @option_parser_factory.option_parser.order!(args) do |non_option|
        first_non_option = non_option
        break
      end
      args.unshift(first_non_option)
    end
  end

  class CommandOptionBlockParser < GLIOptionBlockParser

    def command=(command_being_parsed)
      @extra_error_context = command_being_parsed
    end

  protected

    def break_on_non_option?
      true
    end

    def do_parse(args)
      unknown_options = []
      @option_parser_factory.option_parser.order!(args) do |non_option|
        unknown_options << non_option
        break if break_on_non_option?
      end
      unknown_options.reverse.each do |unknown_option|
        args.unshift(unknown_option)
      end
      args
    end
  end

  class LegacyCommandOptionBlockParser < CommandOptionBlockParser

  protected
    def break_on_non_option?
      false
    end
  end
end
