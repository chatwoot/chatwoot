# frozen_string_literal: true

module Byebug
  #
  # Custom exception exception to signal "command not found" errors
  #
  class CommandNotFound < NoMethodError
    def initialize(input, parent = nil)
      @input = input
      @parent = parent

      super("Unknown command '#{name}'. Try '#{help}'")
    end

    private

    def name
      build_cmd(@parent, @input)
    end

    def help
      build_cmd("help", @parent)
    end

    def build_cmd(*args)
      args.compact.join(" ")
    end
  end
end
