require 'strscan'

# A deliberately small Scheme reader. No Ruby evaluation or host object literals.
class Captain::Apropos::Parser
  MAX_BYTES = 32_768
  MAX_DEPTH = 64

  def initialize(source)
    raise Captain::Apropos::Error, 'Program exceeds 32 KB' if source.bytesize > MAX_BYTES

    @scanner = StringScanner.new(source)
  end

  def parse
    expressions = []
    expressions << read(0) until finished?
    expressions
  end

  private

  def finished?
    @scanner.skip(/(?:\s+|;[^\n]*(?:\n|$))*/)
    @scanner.eos?
  end

  def read(depth)
    raise Captain::Apropos::Error, 'Expression nesting limit reached' if depth > MAX_DEPTH
    raise Captain::Apropos::Error, 'Unexpected end of program' if finished?

    return read_list(depth) if @scanner.scan('(')
    return [:quote, read(depth + 1)] if @scanner.scan('\'')
    return JSON.parse(@scanner.matched) if @scanner.scan(/"(?:[^"\\]|\\.)*"/)

    token = @scanner.scan(/[^\s()'";]+/)
    raise Captain::Apropos::Error, "Unexpected token near #{@scanner.peek(20)}" unless token

    atom(token)
  rescue JSON::ParserError => e
    raise Captain::Apropos::Error, e.message
  end

  def read_list(depth)
    values = []
    loop do
      raise Captain::Apropos::Error, 'Missing closing parenthesis' if finished?
      return values if @scanner.scan(')')

      values << read(depth + 1)
    end
  end

  def atom(token)
    return true if token == '#t'
    return false if token == '#f'
    return token.to_i if token.match?(/\A[+-]?\d+\z/)
    return token.to_f if token.match?(/\A[+-]?\d+\.\d+\z/)

    token.to_sym
  end
end
