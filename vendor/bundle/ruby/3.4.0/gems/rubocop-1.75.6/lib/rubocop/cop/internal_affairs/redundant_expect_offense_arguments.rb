# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant arguments of `RuboCop::RSpec::ExpectOffense`'s methods.
      #
      # @example
      #
      #   # bad
      #   expect_no_offenses('code', keyword: keyword)
      #
      #   # good
      #   expect_no_offenses('code')
      #
      class RedundantExpectOffenseArguments < Base
        extend AutoCorrector

        MSG = 'Remove the redundant arguments.'
        RESTRICT_ON_SEND = %i[expect_no_offenses].freeze

        def on_send(node)
          return if node.arguments.one? || !node.arguments[1]&.hash_type?

          range = node.first_argument.source_range.end.join(node.last_argument.source_range.end)

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end
      end
    end
  end
end
