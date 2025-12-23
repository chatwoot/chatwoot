# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for expectations where `be(...)` can replace `eq(...)`.
      #
      # The `be` matcher compares by identity while the `eq` matcher compares
      # using `==`. Booleans and nil can be compared by identity and therefore
      # the `be` matcher is preferable as it is a more strict test.
      #
      # @safety
      #   This cop is unsafe because it changes how values are compared.
      #
      # @example
      #   # bad
      #   expect(foo).to eq(true)
      #   expect(foo).to eq(false)
      #   expect(foo).to eq(nil)
      #
      #   # good
      #   expect(foo).to be(true)
      #   expect(foo).to be(false)
      #   expect(foo).to be(nil)
      #
      class BeEq < Base
        extend AutoCorrector

        MSG = 'Prefer `be` over `eq`.'
        RESTRICT_ON_SEND = %i[eq].freeze

        # @!method eq_type_with_identity?(node)
        def_node_matcher :eq_type_with_identity?, <<~PATTERN
          (send nil? :eq {boolean nil})
        PATTERN

        def on_send(node)
          return unless eq_type_with_identity?(node)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 'be')
          end
        end
      end
    end
  end
end
