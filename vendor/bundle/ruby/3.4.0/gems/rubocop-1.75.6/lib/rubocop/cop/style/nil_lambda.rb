# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for lambdas and procs that always return nil,
      # which can be replaced with an empty lambda or proc instead.
      #
      # @example
      #   # bad
      #   -> { nil }
      #
      #   lambda do
      #     next nil
      #   end
      #
      #   proc { nil }
      #
      #   Proc.new do
      #     break nil
      #   end
      #
      #   # good
      #   -> {}
      #
      #   lambda do
      #   end
      #
      #   -> (x) { nil if x }
      #
      #   proc {}
      #
      #   Proc.new { nil if x }
      #
      class NilLambda < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use an empty %<type>s instead of always returning nil.'

        # @!method nil_return?(node)
        def_node_matcher :nil_return?, <<~PATTERN
          { ({return next break} nil) (nil) }
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless node.lambda_or_proc?
          return unless nil_return?(node.body)

          message = format(MSG, type: node.lambda? ? 'lambda' : 'proc')
          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          range = if node.single_line?
                    range_with_surrounding_space(node.body.source_range)
                  else
                    range_by_whole_lines(node.body.source_range, include_final_newline: true)
                  end

          corrector.remove(range)
        end
      end
    end
  end
end
