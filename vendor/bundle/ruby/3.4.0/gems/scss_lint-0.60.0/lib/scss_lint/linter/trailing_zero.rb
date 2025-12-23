module SCSSLint
  # Checks for unnecessary trailing zeros in numeric values with decimal points.
  class Linter::TrailingZero < Linter
    include LinterRegistry

    def visit_script_string(node)
      return unless node.type == :identifier

      non_string_values = remove_quoted_strings(node.value).split
      non_string_values.each do |value|
        next unless number = value[FRACTIONAL_DIGIT_REGEX, 1]
        check_for_trailing_zeros(node, number)
      end
    end

    def visit_script_number(node)
      return unless number =
                      source_from_range(node.source_range)[FRACTIONAL_DIGIT_REGEX, 1]

      check_for_trailing_zeros(node, number)
    end

  private

    FRACTIONAL_DIGIT_REGEX = /^-?(\d*\.\d+)/.freeze

    def check_for_trailing_zeros(node, original_number)
      return unless match = /^(\d*\.(?:[0-9]*[1-9]|[1-9])*)0+$/.match(original_number)

      fixed_number = match[1]

      # Handle special case of 0 being the only trailing digit
      fixed_number = fixed_number[0..-2] if fixed_number.end_with?('.')
      fixed_number = 0 if fixed_number.empty? # Handle ".0" -> "0"

      add_lint(node,
               "`#{original_number}` should be written without a trailing " \
               "zero as `#{fixed_number}`")
    end
  end
end
