# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for spaces between `->` and opening parameter
      # parenthesis (`(`) in lambda literals.
      #
      # @example EnforcedStyle: require_no_space (default)
      #     # bad
      #     a = -> (x, y) { x + y }
      #
      #     # good
      #     a = ->(x, y) { x + y }
      #
      # @example EnforcedStyle: require_space
      #     # bad
      #     a = ->(x, y) { x + y }
      #
      #     # good
      #     a = -> (x, y) { x + y }
      class SpaceInLambdaLiteral < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG_REQUIRE_SPACE = 'Use a space between `->` and `(` in lambda literals.'
        MSG_REQUIRE_NO_SPACE = 'Do not use spaces between `->` and `(` in lambda literals.'

        def on_send(node)
          return unless arrow_lambda_with_args?(node)

          if style == :require_space && !space_after_arrow?(node)
            lambda_node = range_of_offense(node)

            add_offense(lambda_node, message: MSG_REQUIRE_SPACE) do |corrector|
              corrector.insert_before(lambda_arguments(node), ' ')
            end
          elsif style == :require_no_space && space_after_arrow?(node)
            space = space_after_arrow(node)

            add_offense(space, message: MSG_REQUIRE_NO_SPACE) do |corrector|
              corrector.remove(space)
            end
          end
        end

        private

        def arrow_lambda_with_args?(node)
          node.lambda_literal? && node.parent.arguments?
        end

        def space_after_arrow?(lambda_node)
          !space_after_arrow(lambda_node).empty?
        end

        def space_after_arrow(lambda_node)
          arrow = lambda_node.parent.children[0].source_range
          parentheses = lambda_node.parent.children[1].source_range

          arrow.end.join(parentheses.begin)
        end

        def range_of_offense(node)
          range_between(
            node.parent.source_range.begin_pos,
            node.parent.arguments.source_range.end_pos
          )
        end

        def lambda_arguments(node)
          node.parent.children[1]
        end
      end
    end
  end
end
