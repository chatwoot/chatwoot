# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of `node.lambda_or_proc?` instead of `node.lambda? || node.proc?`.
      #
      # @example
      #   # bad
      #   node.lambda? || node.proc?
      #   node.proc? || node.lambda?
      #
      #   # good
      #   node.lambda_or_proc?
      #
      class LambdaOrProc < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s`.'

        # @!method lambda_or_proc(node)
        def_node_matcher :lambda_or_proc, <<~PATTERN
          {
            (or $(send _node :lambda?) $(send _node :proc?))
            (or $(send _node :proc?) $(send _node :lambda?))
            (or
              (or _ $(send _node :lambda?)) $(send _node :proc?))
            (or
              (or _ $(send _node :proc?)) $(send _node :lambda?))
          }
        PATTERN

        def on_or(node)
          return unless (lhs, rhs = lambda_or_proc(node))

          offense = lhs.receiver.source_range.join(rhs.source_range.end)
          prefer = "#{lhs.receiver.source}.lambda_or_proc?"

          add_offense(offense, message: format(MSG, prefer: prefer)) do |corrector|
            corrector.replace(offense, prefer)
          end
        end
      end
    end
  end
end
