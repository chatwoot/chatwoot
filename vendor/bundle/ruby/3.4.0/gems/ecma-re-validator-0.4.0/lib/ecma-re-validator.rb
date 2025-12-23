# frozen_string_literal: true

require 'regexp_parser'

module EcmaReValidator
  # JS doesn't have Unicode matching
  UNICODE_CHARACTERS = Regexp::Syntax::Token::UnicodeProperty::All

  INVALID_REGEXP = [
    # JS doesn't have \A, \Z, \z
    :bos, :eos_ob_eol, :eos,
    # JS doesn't have lookbehinds
    :lookbehind, :nlookbehind,
    # JS doesn't have atomic grouping
    :atomic,
    # JS doesn't have possesive quantifiers
    :zero_or_one_possessive, :zero_or_more_possessive, :one_or_more_possessive,
    # JS doesn't have named capture groups
    :named_ab, :named_sq,
    # JS doesn't support modifying options
    :options, :options_switch,
    # JS doesn't support conditionals
    :condition_open,
    # JS doesn't support comments
    :comment
  ].freeze

  INVALID_TOKENS = INVALID_REGEXP + UNICODE_CHARACTERS

  def self.valid?(input)
    if input.is_a? String
      begin
        input = Regexp.new(input)
      rescue RegexpError
        return false
      end
    elsif !input.is_a? Regexp
      return false
    end

    Regexp::Scanner.scan(input).none? do |t|
      if t[1] == :word || t[1] == :space || t[1] == :digit
        t[0] != :type
      else
        INVALID_TOKENS.include?(t[1])
      end
    end
  end
end
