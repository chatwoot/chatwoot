# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for assignments to a local `it` variable inside a block
      # where `it` can refer to the first anonymous parameter as of Ruby 3.4.
      #
      # Although Ruby allows reassigning `it` in these cases, it could
      # cause confusion if `it` is used as a block parameter elsewhere.
      # For consistency, this also applies to numblocks and blocks with
      # parameters, even though `it` cannot be used in those cases.
      #
      # @example
      #   # bad
      #   foo { it = 5 }
      #   foo { |bar| it = bar }
      #   foo { it = _2 }
      #
      #   # good - use a different variable name
      #   foo { var = 5 }
      #   foo { |bar| var = bar }
      #   foo { bar = _2 }
      class ItAssignment < Base
        MSG = '`it` is the default block parameter; consider another name.'

        def on_lvasgn(node)
          return unless node.name == :it
          return unless node.each_ancestor(:any_block).any?

          add_offense(node.loc.name)
        end
      end
    end
  end
end
