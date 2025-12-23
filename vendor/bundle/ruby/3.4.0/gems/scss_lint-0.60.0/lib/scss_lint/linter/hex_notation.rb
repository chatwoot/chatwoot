module SCSSLint
  # Checks if hexadecimal colors are written lowercase / uppercase.
  class Linter::HexNotation < Linter
    include LinterRegistry

    HEX_REGEX = /(#(\h{3}|\h{6}))(?!\h)/.freeze

    def visit_script_color(node)
      return unless hex = source_from_range(node.source_range)[HEX_REGEX, 1]
      check_hex(hex, node)
    end

    def visit_script_string(node)
      return unless node.type == :identifier

      node.value.scan(HEX_REGEX) do |match|
        check_hex(match.first, node)
      end
    end

  private

    def check_hex(hex, node)
      return if expected(hex) == hex

      add_lint(node, "Color `#{hex}` should be written as `#{expected(hex)}`")
    end

    def expected(color)
      return color.downcase if lowercase_style?
      color.upcase
    end

    def lowercase_style?
      config['style'] == 'lowercase'
    end
  end
end
