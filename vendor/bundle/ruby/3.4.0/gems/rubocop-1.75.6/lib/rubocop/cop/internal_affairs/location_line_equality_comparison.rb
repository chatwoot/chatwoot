# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of `same_line?` instead of location line comparison for equality.
      #
      # @example
      #   # bad
      #   node.loc.line == node.parent.loc.line
      #
      #   # bad
      #   node.loc.first_line == node.parent.loc.first_line
      #
      #   # good
      #   same_line?(node, node.parent)
      #
      class LocationLineEqualityComparison < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred>s`.'
        RESTRICT_ON_SEND = [:==].freeze

        # @!method line_send(node)
        def_node_matcher :line_send, <<~PATTERN
          {
            (send (send _ {:loc :source_range}) {:line :first_line})
            (send _ :first_line)
          }
        PATTERN

        # @!method location_line_equality_comparison?(node)
        def_node_matcher :location_line_equality_comparison?, <<~PATTERN
          (send #line_send :== #line_send)
        PATTERN

        def on_send(node)
          return unless location_line_equality_comparison?(node)

          lhs_receiver = extract_receiver(node.receiver)
          rhs_receiver = extract_receiver(node.first_argument)
          preferred = "same_line?(#{lhs_receiver}, #{rhs_receiver})"

          add_offense(node, message: format(MSG, preferred: preferred)) do |corrector|
            corrector.replace(node, preferred)
          end
        end

        private

        def extract_receiver(node)
          receiver = node.receiver
          if receiver.send_type? && (receiver.method?(:loc) || receiver.method?(:source_range))
            receiver = receiver.receiver
          end
          receiver.source
        end
      end
    end
  end
end
