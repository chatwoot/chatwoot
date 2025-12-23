# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Looks for uses of flip-flop operator
      # based on the Ruby Style Guide.
      #
      # Here is the history of flip-flops in Ruby.
      # flip-flop operator is deprecated in Ruby 2.6.0 and
      # the deprecation has been reverted by Ruby 2.7.0 and
      # backported to Ruby 2.6.
      # See: https://bugs.ruby-lang.org/issues/5400
      #
      # @example
      #   # bad
      #   (1..20).each do |x|
      #     puts x if (x == 5) .. (x == 10)
      #   end
      #
      #   # good
      #   (1..20).each do |x|
      #     puts x if (x >= 5) && (x <= 10)
      #   end
      class FlipFlop < Base
        MSG = 'Avoid the use of flip-flop operators.'

        def on_iflipflop(node)
          add_offense(node)
        end

        def on_eflipflop(node)
          add_offense(node)
        end
      end
    end
  end
end
