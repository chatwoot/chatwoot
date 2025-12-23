# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # `BigDecimal.new()` is deprecated since BigDecimal 1.3.3.
      # This cop identifies places where `BigDecimal.new()`
      # can be replaced by `BigDecimal()`.
      #
      # @example
      #   # bad
      #   BigDecimal.new(123.456, 3)
      #
      #   # good
      #   BigDecimal(123.456, 3)
      #
      class BigDecimalNew < Base
        extend AutoCorrector

        MSG = '`BigDecimal.new()` is deprecated. Use `BigDecimal()` instead.'
        RESTRICT_ON_SEND = %i[new].freeze

        # @!method big_decimal_new(node)
        def_node_matcher :big_decimal_new, <<~PATTERN
          (send
            (const ${nil? cbase} :BigDecimal) :new ...)
        PATTERN

        def on_send(node)
          big_decimal_new(node) do |cbase|
            add_offense(node.loc.selector) do |corrector|
              corrector.remove(node.loc.selector)
              corrector.remove(node.loc.dot)
              corrector.remove(cbase) if cbase
            end
          end
        end
      end
    end
  end
end
