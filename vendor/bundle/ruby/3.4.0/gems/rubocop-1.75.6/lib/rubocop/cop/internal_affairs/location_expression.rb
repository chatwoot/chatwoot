# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of `node.source_range` instead of `node.location.expression`.
      #
      # @example
      #
      #   # bad
      #   node.location.expression
      #   node.loc.expression
      #
      #   # good
      #   node.source_range
      #
      class LocationExpression < Base
        extend AutoCorrector

        MSG = 'Use `source_range` instead.'
        RESTRICT_ON_SEND = %i[loc location].freeze

        def on_send(node)
          return unless (parent = node.parent)
          return unless parent.call_type? && parent.method?(:expression)
          return unless parent.receiver.receiver

          offense = node.loc.selector.join(parent.source_range.end)

          add_offense(offense) do |corrector|
            corrector.replace(offense, 'source_range')
          end
        end
        alias on_csend on_send
      end
    end
  end
end
