require 'strscan'

class Captain::Apropos::WootqlLexer
  MAX_BYTES = 32_768
  MAX_TOKENS = 4_096
  Token = Struct.new(:kind, :value, :position)

  attr_reader :tokens

  def initialize(source)
    raise Captain::Apropos::Error, 'WootQL source must be a string of at most 32 KB' unless source.is_a?(String) && source.bytesize <= MAX_BYTES

    @tokens = tokenize(source)
  end

  private

  def tokenize(source)
    scanner = StringScanner.new(source)
    tokens = []
    until scanner.eos?
      scanner.skip(/\s+/)
      break if scanner.eos?

      raise Captain::Apropos::Error, 'WootQL exceeds 4096 tokens' if tokens.size >= MAX_TOKENS

      position = scanner.pos
      kind, value = read_token(scanner)
      tokens << Token.new(kind, value, position)
    end
    tokens << Token.new(:end, nil, source.bytesize)
  rescue JSON::ParserError => e
    raise Captain::Apropos::Error, "Invalid WootQL string: #{e.message}"
  end

  def read_token(scanner)
    return [:string, JSON.parse(scanner.matched)] if scanner.scan(/"(?:[^"\\]|\\.)*"/)
    return [:parameter, scanner.matched.delete_prefix('$')] if scanner.scan(/\$[a-zA-Z_][a-zA-Z0-9_]*/)
    return [:duration, scanner.matched] if scanner.scan(/\d+(?:ms|s|m|h|d|w)\b/)
    return [:number, number(scanner.matched)] if scanner.scan(/\d+(?:\.\d+)?/)
    return [:identifier, scanner.matched] if scanner.scan(/[a-zA-Z_][a-zA-Z0-9_]*/)
    return [scanner.matched, scanner.matched] if scanner.scan(/>=|<=|!=|[|,.()=<>+\-]/)

    raise Captain::Apropos::Error, "Unexpected WootQL token at byte #{scanner.pos}"
  end

  def number(token)
    token.include?('.') ? token.to_f : token.to_i
  end
end
