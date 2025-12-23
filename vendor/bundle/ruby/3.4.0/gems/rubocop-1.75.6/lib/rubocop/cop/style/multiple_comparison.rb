# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks against comparing a variable with multiple items, where
      # `Array#include?`, `Set#include?` or a `case` could be used instead
      # to avoid code repetition.
      # It accepts comparisons of multiple method calls to avoid unnecessary method calls
      # by default. It can be configured by `AllowMethodComparison` option.
      #
      # @example
      #   # bad
      #   a = 'a'
      #   foo if a == 'a' || a == 'b' || a == 'c'
      #
      #   # good
      #   a = 'a'
      #   foo if ['a', 'b', 'c'].include?(a)
      #
      #   VALUES = Set['a', 'b', 'c'].freeze
      #   # elsewhere...
      #   foo if VALUES.include?(a)
      #
      #   case foo
      #   when 'a', 'b', 'c' then foo
      #   # ...
      #   end
      #
      #   # accepted (but consider `case` as above)
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      # @example AllowMethodComparison: true (default)
      #   # good
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      # @example AllowMethodComparison: false
      #   # bad
      #   foo if a == b.lightweight || a == b.heavyweight
      #
      #   # good
      #   foo if [b.lightweight, b.heavyweight].include?(a)
      #
      # @example ComparisonsThreshold: 2 (default)
      #   # bad
      #   foo if a == 'a' || a == 'b'
      #
      # @example ComparisonsThreshold: 3
      #   # good
      #   foo if a == 'a' || a == 'b'
      #
      class MultipleComparison < Base
        extend AutoCorrector

        MSG = 'Avoid comparing a variable with multiple items ' \
              'in a conditional, use `Array#include?` instead.'

        # @!method simple_double_comparison?(node)
        def_node_matcher :simple_double_comparison?, <<~PATTERN
          (send lvar :== lvar)
        PATTERN

        # @!method simple_comparison_lhs(node)
        def_node_matcher :simple_comparison_lhs, <<~PATTERN
          (send ${lvar call} :== $_)
        PATTERN

        # @!method simple_comparison_rhs(node)
        def_node_matcher :simple_comparison_rhs, <<~PATTERN
          (send $_ :== ${lvar call})
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_or(node)
          root_of_or_node = root_of_or_node(node)
          return unless node == root_of_or_node
          return unless nested_comparison?(node)

          return unless (variable, values = find_offending_var(node))
          return if values.size < comparisons_threshold

          range = offense_range(values)

          add_offense(range) do |corrector|
            elements = values.map(&:source).join(', ')
            argument = variable.lvar_type? ? variable_name(variable) : variable.source
            prefer_method = "[#{elements}].include?(#{argument})"

            corrector.replace(range, prefer_method)
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def find_offending_var(node, variables = Set.new, values = [])
          if node.or_type?
            find_offending_var(node.lhs, variables, values)
            find_offending_var(node.rhs, variables, values)
          elsif simple_double_comparison?(node)
            return
          elsif (var, obj = simple_comparison(node))
            return if allow_method_comparison? && obj.call_type?

            variables << var
            return if variables.size > 1

            values << obj
          end

          [variables.first, values] if variables.any?
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def offense_range(values)
          values.first.parent.source_range.begin.join(values.last.parent.source_range.end)
        end

        def variable_name(node)
          node.children[0]
        end

        def nested_comparison?(node)
          if node.or_type?
            node.node_parts.all? { |node_part| comparison? node_part }
          else
            false
          end
        end

        def comparison?(node)
          !!simple_comparison(node) || nested_comparison?(node)
        end

        def simple_comparison(node)
          if (var, obj = simple_comparison_lhs(node)) || (obj, var = simple_comparison_rhs(node))
            return if var.call_type? && !allow_method_comparison?

            [var, obj]
          end
        end

        def root_of_or_node(or_node)
          return or_node unless or_node.parent

          if or_node.parent.or_type?
            root_of_or_node(or_node.parent)
          else
            or_node
          end
        end

        def allow_method_comparison?
          cop_config.fetch('AllowMethodComparison', true)
        end

        def comparisons_threshold
          cop_config.fetch('ComparisonsThreshold', 2)
        end
      end
    end
  end
end
