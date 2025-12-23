# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usage of comparison operators (`==`,
      # `>`, `<`) to test numbers as zero, positive, or negative.
      # These can be replaced by their respective predicate methods.
      # This cop can also be configured to do the reverse.
      #
      # This cop's allowed methods can be customized with `AllowedMethods`.
      # By default, there are no allowed methods.
      #
      # This cop disregards `#nonzero?` as its value is truthy or falsey,
      # but not `true` and `false`, and thus not always interchangeable with
      # `!= 0`.
      #
      # This cop allows comparisons to global variables, since they are often
      # populated with objects which can be compared with integers, but are
      # not themselves `Integer` polymorphic.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   defines the predicates or can be compared to a number, which may lead
      #   to a false positive for non-standard classes.
      #
      # @example EnforcedStyle: predicate (default)
      #   # bad
      #   foo == 0
      #   0 > foo
      #   bar.baz > 0
      #
      #   # good
      #   foo.zero?
      #   foo.negative?
      #   bar.baz.positive?
      #
      # @example EnforcedStyle: comparison
      #   # bad
      #   foo.zero?
      #   foo.negative?
      #   bar.baz.positive?
      #
      #   # good
      #   foo == 0
      #   0 > foo
      #   bar.baz > 0
      #
      # @example AllowedMethods: [] (default) with EnforcedStyle: predicate
      #   # bad
      #   foo == 0
      #   0 > foo
      #   bar.baz > 0
      #
      # @example AllowedMethods: [==] with EnforcedStyle: predicate
      #   # good
      #   foo == 0
      #
      #   # bad
      #   0 > foo
      #   bar.baz > 0
      #
      # @example AllowedPatterns: [] (default) with EnforcedStyle: comparison
      #   # bad
      #   foo.zero?
      #   foo.negative?
      #   bar.baz.positive?
      #
      # @example AllowedPatterns: ['zero'] with EnforcedStyle: predicate
      #   # good
      #   # bad
      #   foo.zero?
      #
      #   # bad
      #   foo.negative?
      #   bar.baz.positive?
      #
      class NumericPredicate < Base
        include ConfigurableEnforcedStyle
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'

        REPLACEMENTS = { 'zero?' => '==', 'positive?' => '>', 'negative?' => '<' }.freeze

        RESTRICT_ON_SEND = %i[== > < positive? negative? zero?].freeze

        def on_send(node)
          numeric, replacement = check(node)
          return unless numeric

          return if allowed_method_name?(node.method_name) ||
                    node.each_ancestor(:send, :block).any? do |ancestor|
                      allowed_method_name?(ancestor.method_name)
                    end

          message = format(MSG, prefer: replacement, current: node.source)
          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        private

        def allowed_method_name?(name)
          allowed_method?(name) || matches_allowed_pattern?(name)
        end

        def check(node)
          numeric, operator =
            if style == :predicate
              comparison(node) || inverted_comparison(node, &invert)
            else
              predicate(node)
            end

          return unless numeric && operator && replacement_supported?(operator)

          [numeric, replacement(node, numeric, operator)]
        end

        def replacement(node, numeric, operation)
          if style == :predicate
            [parenthesized_source(numeric), REPLACEMENTS.invert[operation.to_s]].join('.')
          elsif negated?(node)
            "(#{numeric.source} #{REPLACEMENTS[operation.to_s]} 0)"
          else
            [numeric.source, REPLACEMENTS[operation.to_s], 0].join(' ')
          end
        end

        def parenthesized_source(node)
          if require_parentheses?(node)
            "(#{node.source})"
          else
            node.source
          end
        end

        def require_parentheses?(node)
          node.send_type? && node.binary_operation? && !node.parenthesized?
        end

        def replacement_supported?(operator)
          if %i[> <].include?(operator)
            target_ruby_version >= 2.3
          else
            true
          end
        end

        def invert
          lambda do |comparison, numeric|
            comparison = { :> => :<, :< => :> }[comparison] || comparison

            [numeric, comparison]
          end
        end

        def negated?(node)
          return false unless (parent = node.parent)

          parent.send_type? && parent.method?(:!)
        end

        # @!method predicate(node)
        def_node_matcher :predicate, <<~PATTERN
          (send $(...) ${:zero? :positive? :negative?})
        PATTERN

        # @!method comparison(node)
        def_node_matcher :comparison, <<~PATTERN
          (send [$(...) !gvar_type?] ${:== :> :<} (int 0))
        PATTERN

        # @!method inverted_comparison(node)
        def_node_matcher :inverted_comparison, <<~PATTERN
          (send (int 0) ${:== :> :<} [$(...) !gvar_type?])
        PATTERN
      end
    end
  end
end
