# frozen_string_literal: true

module Byebug
  #
  # Custom interface for easier assertions
  #
  class TestInterface < Interface
    attr_accessor :test_block

    def initialize
      super()

      clear
    end

    def errmsg(message)
      error.concat(prepare(message))
    end

    def print(message)
      output.concat(prepare(message))
    end

    def puts(message)
      output.concat(prepare(message))
    end

    def read_command(prompt)
      cmd = super(prompt)

      return cmd unless cmd.nil? && test_block

      test_block.call
      self.test_block = nil
    end

    def clear
      @input = []
      @output = []
      @error = []
      history.clear
    end

    def inspect
      [
        "Input:", input.join("\n"),
        "Output:", output.join("\n"),
        "Error:", error.join("\n")
      ].join("\n")
    end

    def readline(prompt)
      puts(prompt)

      cmd = input.shift
      cmd.is_a?(Proc) ? cmd.call : cmd
    end

    private

    def prepare(message)
      return message.map(&:to_s) if message.respond_to?(:map)

      message.to_s.split("\n")
    end
  end
end
