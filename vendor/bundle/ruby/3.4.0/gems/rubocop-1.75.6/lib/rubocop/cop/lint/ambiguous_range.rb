# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for ambiguous ranges.
      #
      # Ranges have quite low precedence, which leads to unexpected behavior when
      # using a range with other operators. This cop avoids that by making ranges
      # explicit by requiring parenthesis around complex range boundaries (anything
      # that is not a literal: numerics, strings, symbols, etc.).
      #
      # This cop can be configured with `RequireParenthesesForMethodChains` in order to
      # specify whether method chains (including `self.foo`) should be wrapped in parens
      # by this cop.
      #
      # NOTE: Regardless of this configuration, if a method receiver is a basic literal
      # value, it will be wrapped in order to prevent the ambiguity of `1..2.to_a`.
      #
      # @safety
      #   The cop autocorrects by wrapping the entire boundary in parentheses, which
      #   makes the outcome more explicit but is possible to not be the intention of the
      #   programmer. For this reason, this cop's autocorrect is unsafe (it will not
      #   change the behavior of the code, but will not necessarily match the
      #   intent of the program).
      #
      # @example
      #   # bad
      #   x || 1..2
      #   (x || 1..2)
      #   1..2.to_a
      #
      #   # good, unambiguous
      #   1..2
      #   'a'..'z'
      #   :bar..:baz
      #   MyClass::MIN..MyClass::MAX
      #   @min..@max
      #   a..b
      #   -a..b
      #
      #   # good, ambiguity removed
      #   x || (1..2)
      #   (x || 1)..2
      #   (x || 1)..(y || 2)
      #   (1..2).to_a
      #
      # @example RequireParenthesesForMethodChains: false (default)
      #   # good
      #   a.foo..b.bar
      #   (a.foo)..(b.bar)
      #
      # @example RequireParenthesesForMethodChains: true
      #   # bad
      #   a.foo..b.bar
      #
      #   # good
      #   (a.foo)..(b.bar)
      class AmbiguousRange < Base
        include RationalLiteral
        extend AutoCorrector

        MSG = 'Wrap complex range boundaries with parentheses to avoid ambiguity.'

        def on_irange(node)
          each_boundary(node) do |boundary|
            next if acceptable?(boundary)

            add_offense(boundary) do |corrector|
              corrector.wrap(boundary, '(', ')')
            end
          end
        end
        alias on_erange on_irange

        private

        def each_boundary(range)
          yield range.begin if range.begin
          yield range.end if range.end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def acceptable?(node)
          node.begin_type? ||
            node.literal? || rational_literal?(node) ||
            node.variable? || node.const_type? || node.self_type? ||
            (node.call_type? && acceptable_call?(node))
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def acceptable_call?(node)
          return true if node.unary_operation?

          # Require parentheses when making a method call on a literal
          # to avoid the ambiguity of `1..2.to_a`.
          return false if node.receiver&.basic_literal?

          require_parentheses_for_method_chain? || node.receiver.nil?
        end

        def require_parentheses_for_method_chain?
          !cop_config['RequireParenthesesForMethodChains']
        end
      end
    end
  end
end
