module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    attr_accessor :options

    DEFAULT_OPTIONS = {
      :default_command => nil,
      :autocomplete => true,
      :subcommand_option_handling_strategy => :legacy,
      :argument_handling_strategy => :loose
    }

    def initialize(commands,flags,switches,accepts, options={})
      self.options = DEFAULT_OPTIONS.merge(options)

      command_finder       = CommandFinder.new(commands,
                                               :default_command => (options[:default_command] || :help),
                                               :autocomplete => options[:autocomplete])
      @global_option_parser = GlobalOptionParser.new(OptionParserFactory.new(flags,switches,accepts),command_finder,flags, :command_missing_block => options[:command_missing_block])
      @accepts              = accepts
      if options[:argument_handling_strategy] == :strict && options[:subcommand_option_handling_strategy] != :normal
        raise ArgumentError, "To use strict argument handling, you must enable normal subcommand_option_handling, e.g. subcommand_option_handling :normal"
      end
    end

    # Given the command-line argument array, returns an OptionParsingResult
    def parse_options(args) # :nodoc:
      option_parser_class = self.class.const_get("#{options[:subcommand_option_handling_strategy].to_s.capitalize}CommandOptionParser")
      OptionParsingResult.new.tap { |parsing_result|
        parsing_result.arguments = args
        parsing_result = @global_option_parser.parse!(parsing_result)
        option_parser_class.new(@accepts).parse!(parsing_result, options[:argument_handling_strategy], options[:autocomplete])
      }
    end

  private

    class GlobalOptionParser
      def initialize(option_parser_factory,command_finder,flags,options={})
        @option_parser_factory = option_parser_factory
        @command_finder        = command_finder
        @flags                 = flags
        @options               = options
      end

      def parse!(parsing_result)
        parsing_result.arguments      = GLIOptionBlockParser.new(@option_parser_factory,UnknownGlobalArgument).parse!(parsing_result.arguments)
        parsing_result.global_options = @option_parser_factory.options_hash_with_defaults_set!
        command_name = if parsing_result.global_options[:help] || parsing_result.global_options[:version]
                         "help"
                       else
                         parsing_result.arguments.shift
                       end
        parsing_result.command        = begin
          @command_finder.find_command(command_name)
        rescue UnknownCommand => e
          raise e unless @options[:command_missing_block]
          command = @options[:command_missing_block].call(command_name.to_sym,parsing_result.global_options)
          if command
            unless command.is_a?(Command)
              raise UnknownCommand.new("Expected the `command_missing` block to return a GLI::Command object, got a #{command.class.name} instead.")
            end
          else
            raise e
          end
          command
        end

        unless command_name == 'help'
          verify_required_options!(@flags, parsing_result.command, parsing_result.global_options)
        end
        parsing_result
      end

    protected
      def verify_arguments!(arguments, command)
        # Lets assume that if the user sets a 'arg_name' for the command it is for a complex scenario
        # and we should not validate the arguments
        return unless command.arguments_description.empty?

        # Go through all declared arguments for the command, counting the min and max number
        # of arguments
        min_number_of_arguments = 0
        max_number_of_arguments = 0
        command.arguments.each do |arg|
          if arg.optional?
            max_number_of_arguments = max_number_of_arguments + 1
          else
            min_number_of_arguments = min_number_of_arguments + 1
            max_number_of_arguments = max_number_of_arguments + 1
          end

          # Special case, as soon as we have a 'multiple' arguments, all bets are off for the
          # maximum number of arguments !
          if arg.multiple?
            max_number_of_arguments = 99999
          end
        end

        # Now validate the number of arguments
        num_arguments_range = min_number_of_arguments..max_number_of_arguments
        if !num_arguments_range.cover?(arguments.size)
          raise MissingRequiredArgumentsException.new(command,arguments.size,num_arguments_range)
        end
      end

      def verify_required_options!(flags, command, options)
        missing_required_options = flags.values.
          select(&:required?).
          select { |option|
            options[option.name] == nil ||
            ( options[option.name].kind_of?(Array) && options[option.name].empty? )
          }
        unless missing_required_options.empty?
          raise MissingRequiredOptionsException.new(command,missing_required_options)
        end
      end
    end

    class NormalCommandOptionParser < GlobalOptionParser
      def initialize(accepts)
        @accepts = accepts
      end

      def error_handler
        lambda { |message,extra_error_context|
          raise UnknownCommandArgument.new(message,extra_error_context)
        }
      end

      def parse!(parsing_result,argument_handling_strategy,autocomplete)
        parsed_command_options = {}
        command = parsing_result.command
        arguments = nil

        loop do
          option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
          option_block_parser         = CommandOptionBlockParser.new(option_parser_factory, self.error_handler)
          option_block_parser.command = command
          arguments                   = parsing_result.arguments

          arguments = option_block_parser.parse!(arguments)

          parsed_command_options[command] = option_parser_factory.options_hash_with_defaults_set!
          command_finder                  = CommandFinder.new(command.commands, :default_command => command.get_default_command, :autocomplete => autocomplete)
          next_command_name               = arguments.shift

          verify_required_options!(command.flags, command, parsed_command_options[command])

          begin
            command = command_finder.find_command(next_command_name)
          rescue AmbiguousCommand
            arguments.unshift(next_command_name)
            break
          rescue UnknownCommand
            arguments.unshift(next_command_name)
            # Although command finder could certainly know if it should use
            # the default command, it has no way to put the "unknown command"
            # back into the argument stack.  UGH.
            unless command.get_default_command.nil?
              command = command_finder.find_command(command.get_default_command)
            end
            break
          end
        end
        parsed_command_options[command] ||= {}
        command_options = parsed_command_options[command]

        this_command          = command.parent
        child_command_options = command_options

        while this_command.kind_of?(command.class)
          this_command_options = parsed_command_options[this_command] || {}
          child_command_options[GLI::Command::PARENT] = this_command_options
          this_command = this_command.parent
          child_command_options = this_command_options
        end

        parsing_result.command_options = command_options
        parsing_result.command = command
        parsing_result.arguments = Array(arguments.compact)

        # Lets validate the arguments now that we know for sure the command that is invoked
        verify_arguments!(parsing_result.arguments, parsing_result.command) if argument_handling_strategy == :strict

        parsing_result
      end

    end

    class LegacyCommandOptionParser < NormalCommandOptionParser
      def parse!(parsing_result,argument_handling_strategy,autocomplete)
        command                     = parsing_result.command
        option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
        option_block_parser         = LegacyCommandOptionBlockParser.new(option_parser_factory, self.error_handler)
        option_block_parser.command = command

        parsing_result.arguments       = option_block_parser.parse!(parsing_result.arguments)
        parsing_result.command_options = option_parser_factory.options_hash_with_defaults_set!

        subcommand,args                = find_subcommand(command,parsing_result.arguments,autocomplete)
        parsing_result.command         = subcommand
        parsing_result.arguments       = args
        verify_required_options!(command.flags, parsing_result.command, parsing_result.command_options)
      end

    private

      def find_subcommand(command,arguments,autocomplete)
        arguments = Array(arguments)
        command_name = if arguments.empty?
                         nil
                       else
                         arguments.first
                       end

        default_command = command.get_default_command
        finder = CommandFinder.new(command.commands, :default_command => default_command.to_s, :autocomplete => autocomplete)

        begin
          results = [finder.find_command(command_name),arguments[1..-1]]
          find_subcommand(results[0],results[1],autocomplete)
        rescue UnknownCommand, AmbiguousCommand
          begin
            results = [finder.find_command(default_command.to_s),arguments]
            find_subcommand(results[0],results[1],autocomplete)
          rescue UnknownCommand, AmbiguousCommand
            [command,arguments]
          end
        end
      end
    end
  end
end
