module SCSSLint
  # Checks that hexadecimal colors are written in the desired number of
  # characters.
  class Linter::HexLength < Linter
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

    def expected(hex)
      return short_hex_form(hex) if can_be_shorter?(hex) && short_style?
      return long_hex_form(hex) if hex.length == 4 && !short_style?

      hex
    end

    def can_be_shorter?(hex)
      hex.length == 7 &&
        hex[1] == hex[2] &&
        hex[3] == hex[4] &&
        hex[5] == hex[6]
    end

    def short_hex_form(hex)
      [hex[0..1], hex[3], hex[5]].join
    end

    def long_hex_form(hex)
      [hex[0..1], hex[1], hex[2], hex[2], hex[3], hex[3]].join
    end

    def short_style?
      config['style'] == 'short'
    end
  end
end
