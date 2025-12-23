# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unintended or-assignment to a constant.
      #
      # Constants should always be assigned in the same location. And its value
      # should always be the same. If constants are assigned in multiple
      # locations, the result may vary depending on the order of `require`.
      #
      # @safety
      #   This cop is unsafe because code that is already conditionally
      #   assigning a constant may have its behavior changed by autocorrection.
      #
      # @example
      #
      #   # bad
      #   CONST ||= 1
      #
      #   # good
      #   CONST = 1
      #
      class OrAssignmentToConstant < Base
        extend AutoCorrector

        MSG = 'Avoid using or-assignment with constants.'

        def on_or_asgn(node)
          return unless node.lhs&.casgn_type?

          add_offense(node.loc.operator) do |corrector|
            next if node.each_ancestor(:any_def).any?

            corrector.replace(node.loc.operator, '=')
          end
        end
      end
    end
  end
end
