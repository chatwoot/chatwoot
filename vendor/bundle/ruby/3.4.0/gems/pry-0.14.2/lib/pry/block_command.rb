# frozen_string_literal: true

class Pry
  # A super-class for Commands that are created with a single block.
  #
  # This class ensures that the block is called with the correct number of
  # arguments and the right context.
  #
  # Create subclasses using {Pry::CommandSet#command}.
  class BlockCommand < Command
    # Call the block that was registered with this command.
    # @param [Array<String>] args The arguments passed
    # @return [Object] The return value of the block
    def call(*args)
      instance_exec(*normalize_method_args(block, args), &block)
    end

    def help
      "#{command_options[:listing].to_s.ljust(18)} #{description}"
    end
  end
end
