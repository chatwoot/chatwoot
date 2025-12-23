# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for unparenthesized method calls in the argument list
      # of a parenthesized method call.
      # `be`, `be_a`, `be_an`, `be_between`, `be_falsey`, `be_kind_of`, `be_instance_of`,
      # `be_truthy`, `be_within`, `eq`, `eql`, `end_with`, `include`, `match`, `raise_error`,
      # `respond_to`, and `start_with` methods are allowed by default.
      # These are customizable with `AllowedMethods` option.
      #
      # @example
      #   # good
      #   method1(method2(arg))
      #
      #   # bad
      #   method1(method2 arg)
      #
      # @example AllowedMethods: [foo]
      #   # good
      #   method1(foo arg)
      #
      class NestedParenthesizedCalls < Base
        include RangeHelp
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Add parentheses to nested method call `%<source>s`.'

        def self.autocorrect_incompatible_with
          [Style::MethodCallWithArgsParentheses]
        end

        def on_send(node)
          return unless node.parenthesized?

          node.each_child_node(:call) do |nested|
            next if allowed_omission?(nested)

            message = format(MSG, source: nested.source)
            add_offense(nested, message: message) do |corrector|
              autocorrect(corrector, nested)
            end
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, nested)
          first_arg = nested.first_argument.source_range
          last_arg = nested.last_argument.source_range

          leading_space =
            range_with_surrounding_space(first_arg.begin,
                                         side: :left,
                                         whitespace: true,
                                         continuations: true)

          corrector.replace(leading_space, '(')
          corrector.insert_after(last_arg, ')')
        end

        def allowed_omission?(send_node)
          !send_node.arguments? || send_node.parenthesized? ||
            send_node.setter_method? || send_node.operator_method? ||
            allowed?(send_node)
        end

        def allowed?(send_node)
          send_node.parent.arguments.one? &&
            allowed_method?(send_node.method_name) &&
            send_node.arguments.one?
        end
      end
    end
  end
end
