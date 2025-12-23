# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for uses of numbered parameter assignment.
      # It emulates the following warning in Ruby 2.7:
      #
      #   $ ruby -ve '_1 = :value'
      #   ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-darwin19]
      #   -e:1: warning: `_1' is reserved for numbered parameter; consider another name
      #
      # Assigning to a numbered parameter (from `_1` to `_9`) causes an error in Ruby 3.0.
      #
      #   $ ruby -ve '_1 = :value'
      #   ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin19]
      #   -e:1: _1 is reserved for numbered parameter
      #
      # NOTE: The parametered parameters are from `_1` to `_9`. This cop checks `_0`, and over `_10`
      # as well to prevent confusion.
      #
      # @example
      #
      #   # bad
      #   _1 = :value
      #
      #   # good
      #   non_numbered_parameter_name = :value
      #
      class NumberedParameterAssignment < Base
        NUM_PARAM_MSG = '`_%<number>s` is reserved for numbered parameter; consider another name.'
        LVAR_MSG = '`_%<number>s` is similar to numbered parameter; consider another name.'
        NUMBERED_PARAMETER_RANGE = (1..9).freeze

        def on_lvasgn(node)
          return unless /\A_(\d+)\z/ =~ node.name

          number = Regexp.last_match(1).to_i
          template = NUMBERED_PARAMETER_RANGE.include?(number) ? NUM_PARAM_MSG : LVAR_MSG

          add_offense(node, message: format(template, number: number))
        end
      end
    end
  end
end
