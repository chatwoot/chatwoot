# frozen_string_literal: true

module RuboCop
  # Take a string with embedded escapes, and convert the escapes as the Ruby
  # interpreter would when reading a double-quoted string literal.
  # For example, "\\n" will be converted to "\n".
  class StringInterpreter
    STRING_ESCAPES = {
      '\a' => "\a", '\b' => "\b", '\e' => "\e", '\f' => "\f", '\n' => "\n",
      '\r' => "\r", '\s' => ' ',  '\t' => "\t", '\v' => "\v", "\\\n" => ''
    }.freeze
    STRING_ESCAPE_REGEX = /\\(?:
                            [abefnrstv\n]     |   # simple escapes (above)
                            \d{1,3}           |   # octal byte escape
                            x[0-9a-fA-F]{1,2} |   # hex byte escape
                            u[0-9a-fA-F]{4}   |   # unicode char escape
                            u\{[^}]*\}        |   # extended unicode escape
                            .                     # any other escaped char
                          )/x.freeze

    private_constant :STRING_ESCAPES, :STRING_ESCAPE_REGEX

    class << self
      def interpret(string)
        # We currently don't handle \cx, \C-x, and \M-x
        string.gsub(STRING_ESCAPE_REGEX) do |escape|
          STRING_ESCAPES[escape] || interpret_string_escape(escape)
        end
      end

      private

      def interpret_string_escape(escape)
        case escape[1]
        when 'u'  then interpret_unicode(escape)
        when 'x'  then interpret_hex(escape)
        when /\d/ then interpret_octal(escape)
        else
          escape[1] # literal escaped char, like \\
        end
      end

      def interpret_unicode(escape)
        if escape[2] == '{'
          escape[3..].split(/\s+/).map(&:hex).pack('U*')
        else
          [escape[2..].hex].pack('U')
        end
      end

      def interpret_hex(escape)
        [escape[2..].hex].pack('C')
      end

      def interpret_octal(escape)
        [escape[1..].to_i(8)].pack('C')
      end
    end
  end
end
