# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for an array literal interpolated inside a regexp.
      #
      # When interpolating an array literal, it is converted to a string. This means
      # that when inside a regexp, it acts as a character class but with additional
      # quotes, spaces and commas that are likely not intended. For example,
      # `/#{%w[a b c]}/` parses as `/["a", "b", "c"]/` (or `/["a, bc]/` without
      # repeated characters).
      #
      # The cop can autocorrect to a character class (if all items in the array are a
      # single character) or alternation (if the array contains longer items).
      #
      # NOTE: This only considers interpolated arrays that contain only strings, symbols,
      # integers, and floats. Any other type is not easily convertible to a character class
      # or regexp alternation.
      #
      # @safety
      #   Autocorrection is unsafe because it will change the regexp pattern, by
      #   removing the additional quotes, spaces and commas from the character class.
      #
      # @example
      #   # bad
      #   /#{%w[a b c]}/
      #
      #   # good
      #   /[abc]/
      #
      #   # bad
      #   /#{%w[foo bar baz]}/
      #
      #   # good
      #   /(?:foo|bar|baz)/
      #
      #   # bad - construct a regexp rather than interpolate an array of identifiers
      #   /#{[foo, bar]}/
      #
      class ArrayLiteralInRegexp < Base
        include Interpolation
        extend AutoCorrector

        LITERAL_TYPES = %i[str sym int float true false nil].freeze
        private_constant :LITERAL_TYPES

        MSG_CHARACTER_CLASS = 'Use a character class instead of interpolating an array in a regexp.'
        MSG_ALTERNATION = 'Use alternation instead of interpolating an array in a regexp.'
        MSG_UNKNOWN = 'Use alternation or a character class instead of interpolating an array ' \
                      'in a regexp.'

        def on_interpolation(begin_node)
          return unless (final_node = begin_node.children.last)
          return unless final_node.array_type?
          return unless begin_node.parent.regexp_type?

          if array_of_literal_values?(final_node)
            register_array_of_literal_values(begin_node, final_node)
          else
            register_array_of_nonliteral_values(begin_node)
          end
        end

        private

        def array_of_literal_values?(node)
          node.each_value.all? { |value| value.type?(*LITERAL_TYPES) }
        end

        def register_array_of_literal_values(begin_node, node)
          array_values = array_values(node)

          if character_class?(array_values)
            message = MSG_CHARACTER_CLASS
            replacement = character_class_for(array_values)
          else
            message = MSG_ALTERNATION
            replacement = alternation_for(array_values)
          end

          add_offense(begin_node, message: message) do |corrector|
            corrector.replace(begin_node, replacement)
          end
        end

        def register_array_of_nonliteral_values(node)
          # Add offense but do not correct if the array contains any nonliteral values.
          add_offense(node, message: MSG_UNKNOWN)
        end

        def array_values(node)
          node.each_value.map do |value|
            value.respond_to?(:value) ? value.value : value.source
          end
        end

        def character_class?(values)
          values.all? { |v| v.to_s.length == 1 }
        end

        def character_class_for(values)
          "[#{escape_values(values).join}]"
        end

        def alternation_for(values)
          "(?:#{escape_values(values).join('|')})"
        end

        def escape_values(values)
          # This may add extraneous escape characters, but they can be cleaned up
          # by `Style/RedundantRegexpEscape`.
          values.map { |value| Regexp.escape(value.to_s) }
        end
      end
    end
  end
end
