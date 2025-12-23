# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for spaces inside range literals.
      #
      # @example
      #   # bad
      #   1 .. 3
      #
      #   # good
      #   1..3
      #
      #   # bad
      #   'a' .. 'z'
      #
      #   # good
      #   'a'..'z'
      class SpaceInsideRangeLiteral < Base
        extend AutoCorrector

        MSG = 'Space inside range literal.'

        def on_irange(node)
          check(node)
        end

        def on_erange(node)
          check(node)
        end

        private

        def check(node)
          expression = node.source
          op = node.loc.operator.source
          escaped_op = op.gsub('.', '\.')

          # account for multiline range literals
          expression.sub!(/#{escaped_op}\n\s*/, op)

          return unless /(\s#{escaped_op})|(#{escaped_op}\s)/.match?(expression)

          add_offense(node) do |corrector|
            corrector.replace(
              node, expression.sub(/\s+#{escaped_op}/, op).sub(/#{escaped_op}\s+/, op)
            )
          end
        end
      end
    end
  end
end
