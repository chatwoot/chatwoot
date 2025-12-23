# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/parse"

module Byebug
  #
  # Implements the step functionality.
  #
  # Allows the user the continue execution until the next instruction, possibily
  # in a different frame. Use step to step into method calls or blocks.
  #
  class StepCommand < Command
    include Helpers::ParseHelper

    def self.regexp
      /^\s* s(?:tep)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        s[tep][ times]

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Steps into blocks or methods one or more times"
    end

    def execute
      steps, err = parse_steps(@match[1], "Steps")
      return errmsg(err) unless steps

      context.step_into(steps, context.frame.pos)
      processor.proceed!
    end
  end
end
