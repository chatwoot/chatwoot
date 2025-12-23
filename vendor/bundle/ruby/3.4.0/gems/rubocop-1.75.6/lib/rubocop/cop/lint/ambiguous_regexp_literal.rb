# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for ambiguous regexp literals in the first argument of
      # a method invocation without parentheses.
      #
      # @example
      #
      #   # bad
      #
      #   # This is interpreted as a method invocation with a regexp literal,
      #   # but it could possibly be `/` method invocations.
      #   # (i.e. `do_something./(pattern)./(i)`)
      #   do_something /pattern/i
      #
      #   # good
      #
      #   # With parentheses, there's no ambiguity.
      #   do_something(/pattern/i)
      class AmbiguousRegexpLiteral < Base
        extend AutoCorrector

        MSG = 'Ambiguous regexp literal. Parenthesize the method arguments ' \
              "if it's surely a regexp literal, or add a whitespace to the " \
              'right of the `/` if it should be a division.'

        def on_new_investigation
          processed_source.diagnostics.each do |diagnostic|
            if target_ruby_version >= 3.0
              next unless diagnostic.reason == :ambiguous_regexp
            else
              next unless diagnostic.reason == :ambiguous_literal
            end

            offense_node = find_offense_node_by(diagnostic)

            add_offense(diagnostic.location, severity: diagnostic.level) do |corrector|
              add_parentheses(offense_node, corrector)
            end
          end
        end

        private

        def find_offense_node_by(diagnostic)
          node = processed_source.ast.each_node(:regexp).find do |regexp_node|
            regexp_node.source_range.begin_pos == diagnostic.location.begin_pos
          end
          find_offense_node(node.parent, node)
        end

        def find_offense_node(node, regexp_receiver)
          return node if first_argument_is_regexp?(node) || !node.parent

          if (node.parent.send_type? && node.receiver) ||
             method_chain_to_regexp_receiver?(node, regexp_receiver)
            node = find_offense_node(node.parent, regexp_receiver)
          end

          node
        end

        def first_argument_is_regexp?(node)
          node.send_type? && node.first_argument&.regexp_type?
        end

        def method_chain_to_regexp_receiver?(node, regexp_receiver)
          return false unless (parent = node.parent)
          return false unless (parent_receiver = parent.receiver)

          parent.parent && parent_receiver.receiver == regexp_receiver
        end
      end
    end
  end
end
