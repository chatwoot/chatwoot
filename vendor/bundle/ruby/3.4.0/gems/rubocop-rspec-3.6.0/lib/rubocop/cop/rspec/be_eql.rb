# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for expectations where `be(...)` can replace `eql(...)`.
      #
      # The `be` matcher compares by identity while the `eql` matcher
      # compares using `eql?`. Integers, floats, booleans, symbols, and nil
      # can be compared by identity and therefore the `be` matcher is
      # preferable as it is a more strict test.
      #
      # @safety
      #   This cop is unsafe because it changes how values are compared.
      #
      # @example
      #   # bad
      #   expect(foo).to eql(1)
      #   expect(foo).to eql(1.0)
      #   expect(foo).to eql(true)
      #   expect(foo).to eql(false)
      #   expect(foo).to eql(:bar)
      #   expect(foo).to eql(nil)
      #
      #   # good
      #   expect(foo).to be(1)
      #   expect(foo).to be(1.0)
      #   expect(foo).to be(true)
      #   expect(foo).to be(false)
      #   expect(foo).to be(:bar)
      #   expect(foo).to be(nil)
      #
      # This cop only looks for instances of `expect(...).to eql(...)`. We
      # do not check `to_not` or `not_to` since `!eql?` is more strict
      # than `!equal?`. We also do not try to flag `eq` because if
      # `a == b`, and `b` is comparable by identity, `a` is still not
      # necessarily the same type as `b` since the `#==` operator can
      # coerce objects for comparison.
      #
      class BeEql < Base
        extend AutoCorrector

        MSG = 'Prefer `be` over `eql`.'
        RESTRICT_ON_SEND = %i[to].freeze

        # @!method eql_type_with_identity(node)
        def_node_matcher :eql_type_with_identity, <<~PATTERN
          (send _ :to $(send nil? :eql {boolean int float sym nil}))
        PATTERN

        def on_send(node)
          eql_type_with_identity(node) do |eql|
            add_offense(eql.loc.selector) do |corrector|
              corrector.replace(eql.loc.selector, 'be')
            end
          end
        end
      end
    end
  end
end
