# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant dot before operator method call.
      # The target operator methods are `|`, `^`, `&`, ``<=>``, `==`, `===`, `=~`, `>`, `>=`, `<`,
      # ``<=``, `<<`, `>>`, `+`, `-`, `*`, `/`, `%`, `**`, `~`, `!`, `!=`, and `!~`.
      #
      # @example
      #
      #   # bad
      #   foo.+ bar
      #   foo.& bar
      #
      #   # good
      #   foo + bar
      #   foo & bar
      #
      class OperatorMethodCall < Base
        extend AutoCorrector

        MSG = 'Redundant dot detected.'
        RESTRICT_ON_SEND = %i[| ^ & <=> == === =~ > >= < <= << >> + - * / % ** ~ ! != !~].freeze
        INVALID_SYNTAX_ARG_TYPES = %i[
          splat kwsplat forwarded_args forwarded_restarg forwarded_kwrestarg block_pass
        ].freeze

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        def on_send(node)
          return unless (dot = node.loc.dot)
          return if node.receiver.const_type? || !node.arguments.one?

          return unless (rhs = node.first_argument)
          return if method_call_with_parenthesized_arg?(rhs)
          return if invalid_syntax_argument?(rhs)

          add_offense(dot) do |corrector|
            wrap_in_parentheses_if_chained(corrector, node)
            corrector.replace(dot, ' ')

            selector = node.loc.selector
            corrector.insert_after(selector, ' ') if insert_space_after?(node)
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

        private

        # Checks for an acceptable case of `foo.+(bar).baz`.
        def method_call_with_parenthesized_arg?(argument)
          return false unless argument.parent.parent&.send_type?

          argument.children.first && argument.parent.parenthesized?
        end

        def invalid_syntax_argument?(argument)
          type = argument.hash_type? ? argument.children.first&.type : argument.type

          INVALID_SYNTAX_ARG_TYPES.include?(type)
        end

        def wrap_in_parentheses_if_chained(corrector, node)
          return unless node.parent&.call_type?
          return if node.parent.first_argument == node

          operator = node.loc.selector

          ParenthesesCorrector.correct(corrector, node)
          corrector.insert_after(operator, ' ')
          corrector.wrap(node, '(', ')')
        end

        def insert_space_after?(node)
          rhs = node.first_argument
          selector = node.loc.selector

          return true if selector.end_pos == rhs.source_range.begin_pos
          return false if node.parent&.call_type? # if chained, a space is already added

          # For `/` operations, if the RHS starts with a `(` without space,
          # add one to avoid a syntax error.
          range = selector.end.join(rhs.source_range.begin)
          return true if node.method?(:/) && range.source == '('

          false
        end
      end
    end
  end
end
