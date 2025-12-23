module GLI
  # Mixed into all exceptions that GLI handles; you can use this to catch
  # anything that came from GLI intentionally.  You can also mix this into non-GLI
  # exceptions to get GLI's exit behavior.
  module StandardException
    def exit_code; 1; end
  end

  # Hack to request help from within a command
  # Will *not* be rethrown when GLI_DEBUG is ON
  class RequestHelp < StandardError
    include StandardException
    def exit_code; 0; end

    # The command for which the argument was unknown
    attr_reader :command_in_context

    def initialize(command_in_context)
      @command_in_context = command_in_context
    end
  end

  # Indicates that the command line invocation was bad
  class BadCommandLine < StandardError
    include StandardException
    def exit_code; 64; end
  end

  class PreconditionFailed < StandardError
    include StandardException
    def exit_code; 65; end
  end

  # Indicates the bad command line was an unknown command
  class UnknownCommand < BadCommandLine
  end

  # The command issued partially matches more than one command
  class AmbiguousCommand < BadCommandLine
  end

  # Indicates the bad command line was an unknown global argument
  class UnknownGlobalArgument < BadCommandLine
  end

  class CommandException < BadCommandLine
    # The command for which the argument was unknown
    attr_reader :command_in_context
    # +message+:: the error message to show the user
    # +command+:: the command we were using to parse command-specific options
    def initialize(message,command_in_context,exit_code=nil)
      super(message)
      @command_in_context = command_in_context
      @exit_code = exit_code
    end

    def exit_code
      @exit_code || super
    end
  end

  class BadCommandOptionsOrArguments < BadCommandLine
    # The command for which the argument was unknown
    attr_reader :command_in_context
    def initialize(message,command)
      super(message)
      @command_in_context = command
    end
  end

  class MissingRequiredArgumentsException < BadCommandOptionsOrArguments
    attr_reader :num_arguments_received, :range_arguments_accepted
    def initialize(command,num_arguments_received,range_arguments_accepted)

      @num_arguments_received   = num_arguments_received
      @range_arguments_accepted = range_arguments_accepted

      message = if @num_arguments_received < @range_arguments_accepted.min
                  "#{command.name} expected at least #{@range_arguments_accepted.min} arguments, but was given only #{@num_arguments_received}"
                elsif @range_arguments_accepted.min == 0
                  "#{command.name} expected no arguments, but received #{@num_arguments_received}"
                else
                  "#{command.name} expected only #{@range_arguments_accepted.max} arguments, but received #{@num_arguments_received}"
                end
      super(message,command)
    end

  end

  class MissingRequiredOptionsException < BadCommandOptionsOrArguments
    def initialize(command,missing_required_options)
      message = "#{command.name} requires these options: "
      required_options = missing_required_options.sort.map(&:name).join(", ")
      super(message + required_options,command)
    end
  end

  # Indicates the bad command line was an unknown command argument
  class UnknownCommandArgument < CommandException
  end

  # Raise this if you want to use an exit status that isn't the default
  # provided by GLI.  Note that GLI::App#exit_now! might be a bit more to your liking.
  #
  # Example:
  #
  #     raise CustomExit.new("Not connected to DB",-5) unless connected?
  #     raise CustomExit.new("Bad SQL",-6) unless valid_sql?(args[0])
  #
  class CustomExit < StandardError
    include StandardException
    attr_reader :exit_code #:nodoc:
    # Create a custom exit exception
    #
    # +message+:: String containing error message to show the user
    # +exit_code+:: the exit code to use (as an Int), overridding GLI's default
    def initialize(message,exit_code)
      super(message)
      @exit_code = exit_code
    end
  end
end
