# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Looks for expressions containing multiple binary operators
      # where precedence is ambiguous due to lack of parentheses. For example,
      # in `1 + 2 * 3`, the multiplication will happen before the addition, but
      # lexically it appears that the addition will happen first.
      #
      # The cop does not consider unary operators (ie. `!a` or `-b`) or comparison
      # operators (ie. `a =~ b`) because those are not ambiguous.
      #
      # NOTE: Ranges are handled by `Lint/AmbiguousRange`.
      #
      # @example
      #   # bad
      #   a + b * c
      #   a || b && c
      #   a ** b + c
      #
      #   # good (different precedence)
      #   a + (b * c)
      #   a || (b && c)
      #   (a ** b) + c
      #
      #   # good (same precedence)
      #   a + b + c
      #   a * b / c % d
      class AmbiguousOperatorPrecedence < Base
        extend AutoCorrector

        # See https://ruby-doc.org/core-3.0.2/doc/syntax/precedence_rdoc.html
        PRECEDENCE = [
          %i[**],
          %i[* / %],
          %i[+ -],
          %i[<< >>],
          %i[&],
          %i[| ^],
          %i[&&],
          %i[||]
        ].freeze
        RESTRICT_ON_SEND = PRECEDENCE.flatten.freeze
        MSG = 'Wrap expressions with varying precedence with parentheses to avoid ambiguity.'

        def on_new_investigation
          # Cache the precedence of each node being investigated
          # so that we only need to calculate it once
          @node_precedences = {}
          super
        end

        def on_and(node)
          return unless (parent = node.parent)

          return if parent.begin_type? # if the `and` is in a `begin`, it's parenthesized already
          return unless parent.or_type?

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def on_send(node)
          return if node.parenthesized?

          return unless (parent = node.parent)
          return unless operator?(parent)
          return unless greater_precedence?(node, parent)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def precedence(node)
          @node_precedences.fetch(node) do
            PRECEDENCE.index { |operators| operators.include?(operator_name(node)) }
          end
        end

        def operator?(node)
          (node.send_type? && RESTRICT_ON_SEND.include?(node.method_name)) || node.operator_keyword?
        end

        def greater_precedence?(node1, node2)
          node1_precedence = precedence(node1)
          node2_precedence = precedence(node2)
          return false unless node1_precedence && node2_precedence

          node2_precedence > node1_precedence
        end

        def operator_name(node)
          if node.send_type?
            node.method_name
          else
            node.operator.to_sym
          end
        end

        def autocorrect(corrector, node)
          corrector.wrap(node, '(', ')')
        end
      end
    end
  end
end
