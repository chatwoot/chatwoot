# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where a float argument to BigDecimal should be converted to a string.
      # Initializing from String is faster than from Float for BigDecimal.
      #
      # Also identifies places where an integer string argument to BigDecimal should be converted to
      # an integer. Initializing from Integer is faster than from String for BigDecimal.
      #
      # @example
      #   # bad
      #   BigDecimal(1.2, 3, exception: true)
      #   4.5.to_d(6, exception: true)
      #
      #   # good
      #   BigDecimal('1.2', 3, exception: true)
      #   BigDecimal('4.5', 6, exception: true)
      #
      #   # bad
      #   BigDecimal('1', 2)
      #   BigDecimal('4', 6)
      #
      #   # good
      #   BigDecimal(1, 2)
      #   4.to_d(6)
      #
      class BigDecimalWithNumericArgument < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 3.1

        MSG_FROM_FLOAT_TO_STRING = 'Convert float literal to string and pass it to `BigDecimal`.'
        MSG_FROM_INTEGER_TO_STRING = 'Convert string literal to integer and pass it to `BigDecimal`.'
        RESTRICT_ON_SEND = %i[BigDecimal to_d].freeze

        def_node_matcher :big_decimal_with_numeric_argument, <<~PATTERN
          (send nil? :BigDecimal ${float_type? str_type?} ...)
        PATTERN

        def_node_matcher :to_d, <<~PATTERN
          (send [!nil? ${float_type? str_type?}] :to_d ...)
        PATTERN

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        def on_send(node)
          if (numeric = big_decimal_with_numeric_argument(node))
            if numeric.numeric_type?
              add_offense(numeric, message: MSG_FROM_FLOAT_TO_STRING) do |corrector|
                corrector.wrap(numeric, "'", "'")
              end
            elsif numeric.value.match?(/\A\d+\z/)
              add_offense(numeric, message: MSG_FROM_INTEGER_TO_STRING) do |corrector|
                corrector.replace(numeric, numeric.value)
              end
            end
          elsif (numeric_to_d = to_d(node))
            if numeric_to_d.numeric_type?
              add_offense(numeric_to_d, message: MSG_FROM_FLOAT_TO_STRING) do |corrector|
                big_decimal_args = node.arguments.map(&:source).unshift("'#{numeric_to_d.source}'").join(', ')

                corrector.replace(node, "BigDecimal(#{big_decimal_args})")
              end
            elsif numeric_to_d.value.match?(/\A\d+\z/)
              add_offense(numeric_to_d, message: MSG_FROM_INTEGER_TO_STRING) do |corrector|
                corrector.replace(node, "#{numeric_to_d.value}.to_d")
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      end
    end
  end
end
