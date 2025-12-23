# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks where `contain_exactly` is used.
      #
      # This cop checks for the following:
      #
      # - Prefer `match_array` when matching array values.
      # - Prefer `be_empty` when using `contain_exactly` with no arguments.
      #
      # @example
      #   # bad
      #   it { is_expected.to contain_exactly(*array1, *array2) }
      #
      #   # good
      #   it { is_expected.to match_array(array1 + array2) }
      #
      #   # good
      #   it { is_expected.to contain_exactly(content, *array) }
      #
      class ContainExactly < Base
        extend AutoCorrector

        MSG = 'Prefer `match_array` when matching array values.'
        RESTRICT_ON_SEND = %i[contain_exactly].freeze

        def on_send(node)
          return if node.arguments.empty?

          check_populated_collection(node)
        end

        private

        def check_populated_collection(node)
          return unless node.each_child_node.all?(&:splat_type?)

          add_offense(node) do |corrector|
            autocorrect_for_populated_array(node, corrector)
          end
        end

        def autocorrect_for_populated_array(node, corrector)
          arrays = node.arguments.map do |splat_node|
            splat_node.children.first
          end
          corrector.replace(
            node,
            "match_array(#{arrays.map(&:source).join(' + ')})"
          )
        end
      end
    end
  end
end
