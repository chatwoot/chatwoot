# A very thin wrapper around the scanner that breaks quantified literal runs,
# collects emitted tokens into an array, calculates their nesting depth, and
# normalizes tokens for the parser, and checks if they are implemented by the
# given syntax flavor.
class Regexp::Lexer

  OPENING_TOKENS = %i[
    capture passive lookahead nlookahead lookbehind nlookbehind
    atomic options options_switch named absence open
  ].freeze

  CLOSING_TOKENS = %i[close].freeze

  CONDITION_TOKENS = %i[condition condition_close].freeze

  def self.lex(input, syntax = nil, options: nil, collect_tokens: true, &block)
    new.lex(input, syntax, options: options, collect_tokens: collect_tokens, &block)
  end

  def lex(input, syntax = nil, options: nil, collect_tokens: true, &block)
    syntax = syntax ? Regexp::Syntax.for(syntax) : Regexp::Syntax::CURRENT

    self.block = block
    self.collect_tokens = collect_tokens
    self.tokens = []
    self.prev_token = nil
    self.preprev_token = nil
    self.nesting = 0
    self.set_nesting = 0
    self.conditional_nesting = 0
    self.shift = 0

    Regexp::Scanner.scan(input, options: options, collect_tokens: false) do |type, token, text, ts, te|
      type, token = *syntax.normalize(type, token)
      syntax.check! type, token

      ascend(type, token)

      if (last = prev_token) &&
         type == :quantifier &&
         (
           (last.type == :literal         && (parts = break_literal(last))) ||
           (last.token == :codepoint_list && (parts = break_codepoint_list(last)))
         )
        emit(parts[0])
        last = parts[1]
      end

      current = Regexp::Token.new(type, token, text, ts + shift, te + shift,
                                  nesting, set_nesting, conditional_nesting)

      if type == :conditional && CONDITION_TOKENS.include?(token)
        current = merge_condition(current, last)
      elsif last
        last.next = current
        current.previous = last
        emit(last)
      end

      self.preprev_token = last
      self.prev_token = current

      descend(type, token)
    end

    emit(prev_token) if prev_token

    collect_tokens ? tokens : nil
  end

  def emit(token)
    if block
      # TODO: in v3.0.0, remove `collect_tokens:` kwarg and only collect w/o block
      res = block.call(token)
      tokens << res if collect_tokens
    else
      tokens << token
    end
  end

  class << self
    alias :scan :lex
  end

  private

  attr_accessor :block,
                :collect_tokens, :tokens, :prev_token, :preprev_token,
                :nesting, :set_nesting, :conditional_nesting, :shift

  def ascend(type, token)
    return unless CLOSING_TOKENS.include?(token)

    case type
    when :group, :assertion
      self.nesting = nesting - 1
    when :set
      self.set_nesting = set_nesting - 1
    when :conditional
      self.conditional_nesting = conditional_nesting - 1
    else
      raise "unhandled nesting type #{type}"
    end
  end

  def descend(type, token)
    return unless OPENING_TOKENS.include?(token)

    case type
    when :group, :assertion
      self.nesting = nesting + 1
    when :set
      self.set_nesting = set_nesting + 1
    when :conditional
      self.conditional_nesting = conditional_nesting + 1
    else
      raise "unhandled nesting type #{type}"
    end
  end

  # called by scan to break a literal run that is longer than one character
  # into two separate tokens when it is followed by a quantifier
  def break_literal(token)
    lead, last, _ = token.text.partition(/.\z/mu)
    return if lead.empty?

    token_1 = Regexp::Token.new(:literal, :literal, lead,
              token.ts, (token.te - last.length),
              nesting, set_nesting, conditional_nesting)
    token_2 = Regexp::Token.new(:literal, :literal, last,
              (token.ts + lead.length), token.te,
              nesting, set_nesting, conditional_nesting)

    token_1.previous = preprev_token
    token_1.next = token_2
    token_2.previous = token_1 # .next will be set by #lex
    [token_1, token_2]
  end

  # if a codepoint list is followed by a quantifier, that quantifier applies
  # to the last codepoint, e.g. /\u{61 62 63}{3}/ =~ 'abccc'
  # c.f. #break_literal.
  def break_codepoint_list(token)
    lead, _, tail = token.text.rpartition(' ')
    return if lead.empty?

    token_1 = Regexp::Token.new(:escape, :codepoint_list, lead + '}',
              token.ts, (token.te - tail.length),
              nesting, set_nesting, conditional_nesting)
    token_2 = Regexp::Token.new(:escape, :codepoint_list, '\u{' + tail,
              (token.ts + lead.length + 1), (token.te + 3),
              nesting, set_nesting, conditional_nesting)

    self.shift = shift + 3 # one space less, but extra \, u, {, and }

    token_1.previous = preprev_token
    token_1.next = token_2
    token_2.previous = token_1 # .next will be set by #lex
    [token_1, token_2]
  end

  def merge_condition(current, last)
    token = Regexp::Token.new(:conditional, :condition, last.text + current.text,
      last.ts, current.te, nesting, set_nesting, conditional_nesting)
    token.previous = preprev_token # .next will be set by #lex
    token
  end

end # module Regexp::Lexer
