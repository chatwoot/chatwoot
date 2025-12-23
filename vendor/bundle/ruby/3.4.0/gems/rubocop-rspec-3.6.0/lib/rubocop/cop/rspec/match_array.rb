# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks where `match_array` is used.
      #
      # This cop checks for the following:
      #
      # - Prefer `contain_exactly` when matching an array with values.
      # - Prefer `eq` when using `match_array` with an empty array literal.
      #
      # @example
      #   # bad
      #   it { is_expected.to match_array([content1, content2]) }
      #
      #   # good
      #   it { is_expected.to contain_exactly(content1, content2) }
      #
      #   # good
      #   it { is_expected.to match_array([content] + array) }
      #
      #   # good
      #   it { is_expected.to match_array(%w(tremble in fear foolish mortals)) }
      #
      class MatchArray < Base
        extend AutoCorrector

        MSG = 'Prefer `contain_exactly` when matching an array literal.'
        RESTRICT_ON_SEND = %i[match_array].freeze

        # @!method match_array_with_empty_array?(node)
        def_node_matcher :match_array_with_empty_array?, <<~PATTERN
          (send nil? :match_array (array))
        PATTERN

        def on_send(node)
          return unless node.first_argument&.array_type?
          return if match_array_with_empty_array?(node)

          check_populated_array(node)
        end

        private

        def check_populated_array(node)
          return if node.first_argument.percent_literal?

          add_offense(node) do |corrector|
            array_contents = node.arguments.flat_map(&:to_a)
            corrector.replace(
              node,
              "contain_exactly(#{array_contents.map(&:source).join(', ')})"
            )
          end
        end
      end
    end
  end
end
