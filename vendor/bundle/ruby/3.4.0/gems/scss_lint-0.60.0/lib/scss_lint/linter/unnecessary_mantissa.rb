# frozen_string_literal: true

module SCSSLint
  # Checks for the unnecessary inclusion of a zero-value mantissa in numbers.
  # (e.g. `4.0` could be written as just `4`)
  class Linter::UnnecessaryMantissa < Linter
    include LinterRegistry

    def visit_script_string(node)
      return unless node.type == :identifier
      return if node.value.match?(/^'|"/)
      return if url_literal?(node)

      node.value.scan(REAL_NUMBER_REGEX) do |number, integer, mantissa, units|
        if unnecessary_mantissa?(mantissa)
          add_lint(node, MESSAGE_FORMAT % [number, integer, units])
        end
      end
    end

    def visit_script_number(node)
      return unless match = REAL_NUMBER_REGEX.match(source_from_range(node.source_range))
      return unless unnecessary_mantissa?(match[:mantissa])

      add_lint(node, MESSAGE_FORMAT % [match[:number], match[:integer],
                                       match[:units]])
    end

  private

    REAL_NUMBER_REGEX = /
      \b(?<number>
        (?<integer>\d*)
        \.
        (?<mantissa>\d+)
        (?<units>\w*)
      )\b
    /ix.freeze

    MESSAGE_FORMAT = '`%s` should be written without the mantissa as `%s%s`'.freeze

    def unnecessary_mantissa?(mantissa)
      mantissa !~ /[^0]/
    end

    def url_literal?(node)
      node.value.start_with?('url(')
    end
  end
end
