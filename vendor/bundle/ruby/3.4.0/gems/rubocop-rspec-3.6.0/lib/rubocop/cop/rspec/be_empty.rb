# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer using `be_empty` when checking for an empty array.
      #
      # @example
      #   # bad
      #   expect(array).to contain_exactly
      #   expect(array).to match_array([])
      #
      #   # good
      #   expect(array).to be_empty
      #
      class BeEmpty < Base
        extend AutoCorrector

        MSG = 'Use `be_empty` matchers for checking an empty array.'
        RESTRICT_ON_SEND = %i[contain_exactly match_array].freeze

        # @!method expect_array_matcher?(node)
        def_node_matcher :expect_array_matcher?, <<~PATTERN
          (send
            (send nil? :expect _)
            #Runners.all
            ${
              (send nil? :match_array (array))
              (send nil? :contain_exactly)
            }
            _?
          )
        PATTERN

        def on_send(node)
          expect_array_matcher?(node.parent) do |expect|
            add_offense(expect) do |corrector|
              corrector.replace(expect, 'be_empty')
            end
          end
        end
      end
    end
  end
end
