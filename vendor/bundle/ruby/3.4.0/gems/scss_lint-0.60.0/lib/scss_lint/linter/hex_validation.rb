module SCSSLint
  # Checks for invalid hexadecimal colors.
  class Linter::HexValidation < Linter
    include LinterRegistry

    def visit_script_string(node)
      return unless node.type == :identifier

      node.value.scan(/(?:\W|^)(#\h+)(?:\W|$)/) do |match|
        check_hex(match.first, node)
      end
    end

  private

    HEX_REGEX = /(#(\h{3}|\h{6}|\h{8}))(?!\h)/.freeze

    def check_hex(hex, node)
      return if HEX_REGEX.match?(hex)
      add_lint(node, "Colors must have either three or six digits: `#{hex}`")
    end
  end
end
