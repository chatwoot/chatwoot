# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for mistyped shorthand assignments.
      #
      # @example
      #   # bad
      #   x =- y
      #   x =+ y
      #   x =* y
      #   x =! y
      #
      #   # good
      #   x -= y # or x = -y
      #   x += y # or x = +y
      #   x *= y # or x = *y
      #   x != y # or x = !y
      #
      class AmbiguousAssignment < Base
        include RangeHelp

        MSG = 'Suspicious assignment detected. Did you mean `%<op>s`?'

        SIMPLE_ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn casgn].freeze

        MISTAKES = { '=-' => '-=', '=+' => '+=', '=*' => '*=', '=!' => '!=' }.freeze

        def on_asgn(node)
          return unless (rhs = rhs(node))

          range = range_between(node.loc.operator.end_pos - 1, rhs.source_range.begin_pos + 1)
          source = range.source
          return unless MISTAKES.key?(source)

          add_offense(range, message: format(MSG, op: MISTAKES[source]))
        end

        SIMPLE_ASSIGNMENT_TYPES.each { |asgn_type| alias_method :"on_#{asgn_type}", :on_asgn }

        private

        def rhs(node)
          if node.casgn_type?
            node.children[2]
          else
            node.children[1]
          end
        end
      end
    end
  end
end
