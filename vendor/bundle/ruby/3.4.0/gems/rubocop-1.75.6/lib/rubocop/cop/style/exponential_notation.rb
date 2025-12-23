# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces consistency when using exponential notation
      # for numbers in the code (eg 1.2e4). Different styles are supported:
      #
      # * `scientific` which enforces a mantissa between 1 (inclusive) and 10 (exclusive).
      # * `engineering` which enforces the exponent to be a multiple of 3 and the mantissa
      #   to be between 0.1 (inclusive) and 1000 (exclusive).
      # * `integral` which enforces the mantissa to always be a whole number without
      #   trailing zeroes.
      #
      # @example EnforcedStyle: scientific (default)
      #   # Enforces a mantissa between 1 (inclusive) and 10 (exclusive).
      #
      #   # bad
      #   10e6
      #   0.3e4
      #   11.7e5
      #   3.14e0
      #
      #   # good
      #   1e7
      #   3e3
      #   1.17e6
      #   3.14
      #
      # @example EnforcedStyle: engineering
      #   # Enforces using multiple of 3 exponents,
      #   # mantissa should be between 0.1 (inclusive) and 1000 (exclusive)
      #
      #   # bad
      #   3.2e7
      #   0.1e5
      #   12e5
      #   1232e6
      #
      #   # good
      #   32e6
      #   10e3
      #   1.2e6
      #   1.232e9
      #
      # @example EnforcedStyle: integral
      #   # Enforces the mantissa to have no decimal part and no
      #   # trailing zeroes.
      #
      #   # bad
      #   3.2e7
      #   0.1e5
      #   120e4
      #
      #   # good
      #   32e6
      #   1e4
      #   12e5
      #
      class ExponentialNotation < Base
        include ConfigurableEnforcedStyle
        MESSAGES = {
          scientific: 'Use a mantissa >= 1 and < 10.',
          engineering: 'Use an exponent divisible by 3 and a mantissa >= 0.1 and < 1000.',
          integral: 'Use an integer as mantissa, without trailing zero.'
        }.freeze

        def on_float(node)
          add_offense(node) if offense?(node)
        end

        private

        def scientific?(node)
          mantissa, = node.source.split('e')
          /^-?[1-9](\.\d*[0-9])?$/.match?(mantissa)
        end

        def engineering?(node)
          mantissa, exponent = node.source.split('e')
          return false unless /^-?\d+$/.match?(exponent)
          return false unless (exponent.to_i % 3).zero?
          return false if /^-?\d{4}/.match?(mantissa)
          return false if /^-?0\d/.match?(mantissa)
          return false if /^-?0.0/.match?(mantissa)

          true
        end

        def integral(node)
          mantissa, = node.source.split('e')
          /^-?[1-9](\d*[1-9])?$/.match?(mantissa)
        end

        def offense?(node)
          return false unless node.source['e']

          case style
          when :scientific
            !scientific?(node)
          when :engineering
            !engineering?(node)
          when :integral
            !integral(node)
          else
            false
          end
        end

        def message(_node)
          MESSAGES[style]
        end
      end
    end
  end
end
