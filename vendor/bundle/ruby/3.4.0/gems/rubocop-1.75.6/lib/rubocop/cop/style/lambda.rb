# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # (by default) checks for uses of the lambda literal syntax for
      # single line lambdas, and the method call syntax for multiline lambdas.
      # It is configurable to enforce one of the styles for both single line
      # and multiline lambdas as well.
      #
      # @example EnforcedStyle: line_count_dependent (default)
      #   # bad
      #   f = lambda { |x| x }
      #   f = ->(x) do
      #         x
      #       end
      #
      #   # good
      #   f = ->(x) { x }
      #   f = lambda do |x|
      #         x
      #       end
      #
      # @example EnforcedStyle: lambda
      #   # bad
      #   f = ->(x) { x }
      #   f = ->(x) do
      #         x
      #       end
      #
      #   # good
      #   f = lambda { |x| x }
      #   f = lambda do |x|
      #         x
      #       end
      #
      # @example EnforcedStyle: literal
      #   # bad
      #   f = lambda { |x| x }
      #   f = lambda do |x|
      #         x
      #       end
      #
      #   # good
      #   f = ->(x) { x }
      #   f = ->(x) do
      #         x
      #       end
      class Lambda < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        LITERAL_MESSAGE = 'Use the `-> { ... }` lambda literal syntax for %<modifier>s lambdas.'
        METHOD_MESSAGE = 'Use the `lambda` method for %<modifier>s lambdas.'

        OFFENDING_SELECTORS = {
          style: {
            lambda: { single_line: '->', multiline: '->' },
            literal: { single_line: 'lambda', multiline: 'lambda' },
            line_count_dependent: { single_line: 'lambda', multiline: '->' }
          }
        }.freeze

        def on_block(node)
          return unless node.lambda?

          selector = node.send_node.source

          return unless offending_selector?(node, selector)

          add_offense(node.send_node, message: message(node, selector)) do |corrector|
            if node.send_node.lambda_literal?
              LambdaLiteralToMethodCorrector.new(node).call(corrector)
            else
              autocorrect_method_to_literal(corrector, node)
            end
          end
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def offending_selector?(node, selector)
          lines = node.multiline? ? :multiline : :single_line

          selector == OFFENDING_SELECTORS[:style][style][lines]
        end

        def message(node, selector)
          message = selector == '->' ? METHOD_MESSAGE : LITERAL_MESSAGE

          format(message, modifier: message_line_modifier(node))
        end

        def message_line_modifier(node)
          case style
          when :line_count_dependent
            node.multiline? ? 'multiline' : 'single line'
          else
            'all'
          end
        end

        def autocorrect_method_to_literal(corrector, node)
          corrector.replace(node.send_node, '->')

          return unless node.arguments?

          arg_str = "(#{lambda_arg_string(node.arguments)})"

          corrector.insert_after(node.send_node, arg_str)
          corrector.remove(arguments_with_whitespace(node))
        end

        def arguments_with_whitespace(node)
          node.loc.begin.end.join(node.arguments.loc.end)
        end

        def lambda_arg_string(args)
          args.children.map(&:source).join(', ')
        end
      end
    end
  end
end
