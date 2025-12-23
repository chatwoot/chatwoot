# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Forbids Yoda expressions, i.e. binary operations (using `*`, `+`, `&`, `|`,
      # and `^` operators) where the order of expression is reversed, eg. `1 + x`.
      # This cop complements `Style/YodaCondition` cop, which has a similar purpose.
      #
      # This cop is disabled by default to respect user intentions such as:
      #
      # [source,ruby]
      # ----
      # config.server_port = 9000 + ENV["TEST_ENV_NUMBER"].to_i
      # ----
      #
      # @safety
      #   This cop is unsafe because binary operators can be defined
      #   differently on different classes, and are not guaranteed to
      #   have the same result if reversed.
      #
      # @example SupportedOperators: ['*', '+', '&', '|', '^'] (default)
      #   # bad
      #   10 * y
      #   1 + x
      #   1 & z
      #   1 | x
      #   1 ^ x
      #   1 + CONST
      #
      #   # good
      #   y * 10
      #   x + 1
      #   z & 1
      #   x | 1
      #   x ^ 1
      #   CONST + 1
      #   60 * 24
      #
      class YodaExpression < Base
        extend AutoCorrector

        MSG = 'Non-literal operand (`%<source>s`) should be first.'

        RESTRICT_ON_SEND = %i[* + & | ^].freeze

        def on_new_investigation
          @offended_nodes = nil
        end

        def on_send(node)
          return unless supported_operators.include?(node.method_name.to_s)
          return unless node.arguments?

          lhs = node.receiver
          rhs = node.first_argument
          return unless yoda_expression_constant?(lhs, rhs)
          return if offended_ancestor?(node)

          message = format(MSG, source: rhs.source)
          add_offense(node, message: message) do |corrector|
            corrector.swap(lhs, rhs)
          end

          offended_nodes.add(node)
        end

        private

        def yoda_expression_constant?(lhs, rhs)
          constant_portion?(lhs) && !constant_portion?(rhs)
        end

        def constant_portion?(node)
          node.type?(:numeric, :const)
        end

        def supported_operators
          Array(cop_config['SupportedOperators'])
        end

        def offended_ancestor?(node)
          node.each_ancestor(:send).any? { |ancestor| @offended_nodes&.include?(ancestor) }
        end

        def offended_nodes
          @offended_nodes ||= Set.new.compare_by_identity
        end
      end
    end
  end
end
