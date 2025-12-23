# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Implements the next functionality.
  #
  # Allows the user the continue execution until the next instruction in the
  # current frame.
  #
  class NextCommand < Command
    include Helpers::ParseHelper

    def self.regexp
      /^\s* n(?:ext)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        n[ext][ nnn]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Runs one or more lines of code"
    end

    def execute
      steps, err = parse_steps(@match[1], "Next")
      return errmsg(err) unless steps

      context.step_over(steps, context.frame.pos)
      processor.proceed!
    end
  end
end
