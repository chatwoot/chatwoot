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

  def self.write(value)
    Writer.new(value).write
  end

  def self.write_atom(value)
    return '()' if value.equal?(EMPTY)
    return '#<unspecified>' if value.equal?(UNSPECIFIED)

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
    when Numeric then value.to_s
    else '#<procedure>'
    end
  end
end

class Scheme::Writer
  def initialize(value)
    @pending = [[:value, value]]
    @active = {}.compare_by_identity
    @output = +''
  end

  # Use an explicit traversal stack for values built at runtime, whose nesting
  # is not bounded by the reader. Removing objects on exit distinguishes cycles
  # from shared structure without copying the whole ancestor set at each level.
  def write
    until @pending.empty?
      operation, value = @pending.pop
      case operation
      when :value then write_value(value)
      when :tail then write_tail(value)
      when :text then @output << value
      when :leave then @active.delete(value)
      end
    end
    @output
  end

  private

  def write_value(value)
    if @active[value]
      @output << '#<cycle>'
    elsif value.is_a?(Scheme::Pair)
      @output << '('
      enqueue_pair(value)
    elsif value.is_a?(Scheme::Vector) || value.is_a?(Scheme::Bytevector)
      @output << (value.is_a?(Scheme::Bytevector) ? '#u8(' : '#(')
      @active[value] = true
      @pending.push([:leave, value], [:text, ')'])
      (value.items.length - 1).downto(0) do |index|
        @pending << [:value, value.items[index]]
        @pending << [:text, ' '] if index.positive?
      end
    else
      @output << Scheme.write_atom(value)
    end
  end

  def write_tail(value)
    if value.equal?(Scheme::EMPTY)
      @output << ')'
    elsif value.is_a?(Scheme::Pair) && !@active[value]
      @output << ' '
      enqueue_pair(value)
    else
      @output << ' . '
      @pending.push([:text, ')'], [:value, value])
    end
  end

  def enqueue_pair(value)
    @active[value] = true
    @pending.push([:leave, value], [:tail, value.cdr], [:value, value.car])
  end
end
