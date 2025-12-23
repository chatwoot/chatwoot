# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant `send_node` method dispatch node.
      #
      # @example
      #
      #   # bad
      #   node.send_node.method_name
      #
      #   # good
      #   node.method_name
      #
      #   # bad
      #   node.send_node.method?(:method_name)
      #
      #   # good
      #   node.method?(:method_name)
      #
      #   # bad
      #   node.send_node.receiver
      #
      #   # good
      #   node.receiver
      #
      class RedundantMethodDispatchNode < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the redundant `send_node`.'
        RESTRICT_ON_SEND = %i[method_name method? receiver].freeze

        # @!method dispatch_method(node)
        def_node_matcher :dispatch_method, <<~PATTERN
          {
            (send $(send _ :send_node) {:method_name :receiver})
            (send $(send _ :send_node) :method? _)
          }
        PATTERN

        def on_send(node)
          return unless (dispatch_node = dispatch_method(node))
          return unless (dot = dispatch_node.loc.dot)

          range = range_between(dot.begin_pos, dispatch_node.loc.selector.end_pos)

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end
      end
    end
  end
end
