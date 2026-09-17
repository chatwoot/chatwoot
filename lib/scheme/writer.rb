module Scheme
  BARE_SYMBOL = %r{\A(?:[[:alpha:]!$%&*/:<=>?^_~][[:alnum:]!$%&*/:<=>?^_~+.@-]*|[+-]|\.\.\.)\z}
  WRITE_ESCAPES = { "\a" => '\\a', "\b" => '\\b', "\t" => '\\t', "\n" => '\\n', "\r" => '\\r' }.freeze

  def self.write_quoted(text, delimiter)
    escaped = text.each_char.map do |char|
      if char == delimiter || char == '\\'
        "\\#{char}"
      elsif WRITE_ESCAPES.key?(char)
        WRITE_ESCAPES.fetch(char)
      elsif char.ord < 32 || char.ord.between?(127, 159)
        "\\x#{char.ord.to_s(16)};"
      else
        char
      end
    end.join
    "#{delimiter}#{escaped}#{delimiter}"
  end

  def self.write(value, active = {}.compare_by_identity)
    return '()' if value.equal?(EMPTY)
    return '#<unspecified>' if value.equal?(UNSPECIFIED)
    return '#<cycle>' if active[value]

    case value
    when true then '#t'
    when false then '#f'
    when String then write_quoted(value, '"')
    when Symbol then value.to_s.match?(BARE_SYMBOL) ? value.to_s : write_quoted(value.to_s, '|')
    when Character then "#\\#{Reader::CHARACTER_NAMES.key(value.value) || value.value}"
    when Rational then "#{value.numerator}/#{value.denominator}"
    when Float
      return '+nan.0' if value.nan?
      return value.positive? ? '+inf.0' : '-inf.0' if value.infinite?

      value.to_s
    when Pair
      parts = []
      cursor = value
      path = active.dup
      while cursor.is_a?(Pair) && !path[cursor]
        path[cursor] = true
        parts << write(cursor.car, path)
        cursor = cursor.cdr
      end
      suffix = cursor.equal?(EMPTY) ? '' : " . #{write(cursor, path)}"
      "(#{parts.join(' ')}#{suffix})"
    when Vector, Bytevector
      path = active.merge(value => true)
      "#{value.is_a?(Bytevector) ? '#u8' : '#'}(#{value.items.map { |item| write(item, path) }.join(' ')})"
    when Numeric then value.to_s
    else '#<procedure>'
    end
  end
end
