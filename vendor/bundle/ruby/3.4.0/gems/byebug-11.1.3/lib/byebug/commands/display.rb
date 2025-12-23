# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"

module Byebug
  #
  # Custom expressions to be displayed every time the debugger stops.
  #
  class DisplayCommand < Command
    include Helpers::EvalHelper

    self.allow_in_post_mortem = false
    self.always_run = 2

    def self.regexp
      /^\s* disp(?:lay)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        disp[lay][ <expression>]

        #{short_description}

        If <expression> specified, adds <expression> into display expression
        list. Otherwise, it lists all expressions.
      DESCRIPTION
    end

    def self.short_description
      "Evaluates expressions every time the debugger stops"
    end

    def execute
      return print_display_expressions unless @match && @match[1]

      Byebug.displays.push [true, @match[1]]
      display_expression(@match[1])
    end

    private

    def display_expression(exp)
      print pr("display.result", n: Byebug.displays.size,
                                 exp: exp,
                                 result: eval_expr(exp))
    end

    def print_display_expressions
      result = prc("display.result", Byebug.displays) do |item, index|
        active, exp = item

        { n: index + 1, exp: exp, result: eval_expr(exp) } if active
      end

      print result
    end

    def eval_expr(expression)
      error_eval(expression).inspect
    rescue StandardError
      "(undefined)"
    end
  end
end
