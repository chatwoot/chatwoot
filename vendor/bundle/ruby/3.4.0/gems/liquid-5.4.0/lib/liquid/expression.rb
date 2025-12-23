# frozen_string_literal: true

module Liquid
  class Expression
    LITERALS = {
      nil => nil, 'nil' => nil, 'null' => nil, '' => nil,
      'true' => true,
      'false' => false,
      'blank' => '',
      'empty' => ''
    }.freeze

    INTEGERS_REGEX       = /\A(-?\d+)\z/
    FLOATS_REGEX         = /\A(-?\d[\d\.]+)\z/

    # Use an atomic group (?>...) to avoid pathological backtracing from
    # malicious input as described in https://github.com/Shopify/liquid/issues/1357
    RANGES_REGEX         = /\A\(\s*(?>(\S+)\s*\.\.)\s*(\S+)\s*\)\z/

    def self.parse(markup)
      return nil unless markup

      markup = markup.strip
      if (markup.start_with?('"') && markup.end_with?('"')) ||
         (markup.start_with?("'") && markup.end_with?("'"))
        return markup[1..-2]
      end

      case markup
      when INTEGERS_REGEX
        Regexp.last_match(1).to_i
      when RANGES_REGEX
        RangeLookup.parse(Regexp.last_match(1), Regexp.last_match(2))
      when FLOATS_REGEX
        Regexp.last_match(1).to_f
      else
        if LITERALS.key?(markup)
          LITERALS[markup]
        else
          VariableLookup.parse(markup)
        end
      end
    end
  end
end
