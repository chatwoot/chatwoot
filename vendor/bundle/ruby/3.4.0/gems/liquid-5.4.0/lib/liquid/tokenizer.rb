# frozen_string_literal: true

module Liquid
  class Tokenizer
    attr_reader :line_number, :for_liquid_tag

    def initialize(source, line_numbers = false, line_number: nil, for_liquid_tag: false)
      @source         = source.to_s.to_str
      @line_number    = line_number || (line_numbers ? 1 : nil)
      @for_liquid_tag = for_liquid_tag
      @tokens         = tokenize
    end

    def shift
      (token = @tokens.shift) || return

      if @line_number
        @line_number += @for_liquid_tag ? 1 : token.count("\n")
      end

      token
    end

    private

    def tokenize
      return [] if @source.empty?

      return @source.split("\n") if @for_liquid_tag

      tokens = @source.split(TemplateParser)

      # removes the rogue empty element at the beginning of the array
      tokens.shift if tokens[0]&.empty?

      tokens
    end
  end
end
