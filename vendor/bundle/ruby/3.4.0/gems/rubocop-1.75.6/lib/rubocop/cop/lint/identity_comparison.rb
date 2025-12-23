# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Prefer `equal?` over `==` when comparing `object_id`.
      #
      # `Object#equal?` is provided to compare objects for identity, and in contrast
      # `Object#==` is provided for the purpose of doing value comparison.
      #
      # @example
      #   # bad
      #   foo.object_id == bar.object_id
      #
      #   # good
      #   foo.equal?(bar)
      #
      class IdentityComparison < Base
        extend AutoCorrector

        MSG = 'Use `equal?` instead `==` when comparing `object_id`.'
        RESTRICT_ON_SEND = %i[==].freeze

        def on_send(node)
          return unless compare_between_object_id_by_double_equal?(node)

          add_offense(node) do |corrector|
            receiver = node.receiver.receiver
            argument = node.first_argument.receiver
            return unless receiver && argument

            replacement = "#{receiver.source}.equal?(#{argument.source})"

            corrector.replace(node, replacement)
          end
        end

        private

        def compare_between_object_id_by_double_equal?(node)
          object_id_method?(node.receiver) && object_id_method?(node.first_argument)
        end

        def object_id_method?(node)
          node.send_type? && node.method?(:object_id)
        end
      end
    end
  end
end
