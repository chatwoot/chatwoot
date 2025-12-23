# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for equality assertions with identical expressions on both sides.
      #
      # @example
      #   # bad
      #   expect(foo.bar).to eq(foo.bar)
      #   expect(foo.bar).to eql(foo.bar)
      #
      #   # good
      #   expect(foo.bar).to eq(2)
      #   expect(foo.bar).to eql(2)
      #
      class IdenticalEqualityAssertion < Base
        MSG = 'Identical expressions on both sides of the equality ' \
              'may indicate a flawed test.'
        RESTRICT_ON_SEND = %i[to].freeze

        # @!method equality_check?(node)
        def_node_matcher :equality_check?, <<~PATTERN
          (send (send nil? :expect $_) :to
            {(send nil? {:eql :eq :be} $_)
             (send (send nil? :be) :== $_)})
        PATTERN

        def on_send(node)
          equality_check?(node) do |left, right|
            add_offense(node) if left == right
          end
        end
      end
    end
  end
end
