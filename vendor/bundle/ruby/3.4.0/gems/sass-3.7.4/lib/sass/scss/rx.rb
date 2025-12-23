# -*- coding: utf-8 -*-
module Sass
  module SCSS
    # A module containing regular expressions used
    # for lexing tokens in an SCSS document.
    # Most of these are taken from [the CSS3 spec](http://www.w3.org/TR/css3-syntax/#lexical),
    # although some have been modified for various reasons.
    module RX
      # Takes a string and returns a CSS identifier
      # that will have the value of the given string.
      #
      # @param str [String] The string to escape
      # @return [String] The escaped string
      def self.escape_ident(str)
        return "" if str.empty?
        return "\\#{str}" if str == '-' || str == '_'
        out = ""
        value = str.dup
        out << value.slice!(0...1) if value =~ /^[-_]/
        if value[0...1] =~ NMSTART
          out << value.slice!(0...1)
        else
          out << escape_char(value.slice!(0...1))
        end
        out << value.gsub(/[^a-zA-Z0-9_-]/) {|c| escape_char c}
        out
      end

      # Escapes a single character for a CSS identifier.
      #
      # @param c [String] The character to escape. Should have length 1
      # @return [String] The escaped character
      # @private
      def self.escape_char(c)
        return "\\%06x" % c.ord unless c =~ %r{[ -/:-~]}
        "\\#{c}"
      end

      # Creates a Regexp from a plain text string,
      # escaping all significant characters.
      #
      # @param str [String] The text of the regexp
      # @param flags [Integer] Flags for the created regular expression
      # @return [Regexp]
      # @private
      def self.quote(str, flags = 0)
        Regexp.new(Regexp.quote(str), flags)
      end

      H        = /[0-9a-fA-F]/
      NL       = /\n|\r\n|\r|\f/
      UNICODE  = /\\#{H}{1,6}[ \t\r\n\f]?/
      s = '\u{80}-\u{D7FF}\u{E000}-\u{FFFD}\u{10000}-\u{10FFFF}'
      NONASCII = /[#{s}]/
      ESCAPE   = /#{UNICODE}|\\[^0-9a-fA-F\r\n\f]/
      NMSTART  = /[_a-zA-Z]|#{NONASCII}|#{ESCAPE}/
      NMCHAR   = /[a-zA-Z0-9_-]|#{NONASCII}|#{ESCAPE}/
      STRING1  = /\"((?:[^\n\r\f\\"]|\\#{NL}|#{ESCAPE})*)\"/
      STRING2  = /\'((?:[^\n\r\f\\']|\\#{NL}|#{ESCAPE})*)\'/

      IDENT    = /-*#{NMSTART}#{NMCHAR}*/
      NAME     = /#{NMCHAR}+/
      STRING   = /#{STRING1}|#{STRING2}/
      URLCHAR  = /[#%&*-~]|#{NONASCII}|#{ESCAPE}/
      URL      = /(#{URLCHAR}*)/
      W        = /[ \t\r\n\f]*/
      VARIABLE = /(\$)(#{Sass::SCSS::RX::IDENT})/

      # This is more liberal than the spec's definition,
      # but that definition didn't work well with the greediness rules
      RANGE    = /(?:#{H}|\?){1,6}/

      ##

      S = /[ \t\r\n\f]+/

      COMMENT = %r{/\*([^*]|\*+[^/*])*\**\*/}
      SINGLE_LINE_COMMENT = %r{//.*(\n[ \t]*//.*)*}

      CDO            = quote("<!--")
      CDC            = quote("-->")
      INCLUDES       = quote("~=")
      DASHMATCH      = quote("|=")
      PREFIXMATCH    = quote("^=")
      SUFFIXMATCH    = quote("$=")
      SUBSTRINGMATCH = quote("*=")

      HASH = /##{NAME}/

      IMPORTANT = /!#{W}important/i

      # A unit is like an IDENT, but disallows a hyphen followed by a digit.
      # This allows "1px-2px" to be interpreted as subtraction rather than "1"
      # with the unit "px-2px". It also allows "%".
      UNIT = /-?#{NMSTART}(?:[a-zA-Z0-9_]|#{NONASCII}|#{ESCAPE}|-(?!\.?\d))*|%/

      UNITLESS_NUMBER = /(?:[0-9]+|[0-9]*\.[0-9]+)(?:[eE][+-]?\d+)?/
      NUMBER = /#{UNITLESS_NUMBER}(?:#{UNIT})?/
      PERCENTAGE = /#{UNITLESS_NUMBER}%/

      URI = /url\(#{W}(?:#{STRING}|#{URL})#{W}\)/i
      FUNCTION = /#{IDENT}\(/

      UNICODERANGE = /u\+(?:#{H}{1,6}-#{H}{1,6}|#{RANGE})/i

      # Defined in http://www.w3.org/TR/css3-selectors/#lex
      PLUS = /#{W}\+/
      GREATER = /#{W}>/
      TILDE = /#{W}~/
      NOT = quote(":not(", Regexp::IGNORECASE)

      # Defined in https://developer.mozilla.org/en/CSS/@-moz-document as a
      # non-standard version of http://www.w3.org/TR/css3-conditional/
      URL_PREFIX = /url-prefix\(#{W}(?:#{STRING}|#{URL})#{W}\)/i
      DOMAIN = /domain\(#{W}(?:#{STRING}|#{URL})#{W}\)/i

      # Custom
      HEXCOLOR = /\#[0-9a-fA-F]+/
      INTERP_START = /#\{/
      ANY = /:(-[-\w]+-)?any\(/i
      OPTIONAL = /!#{W}optional/i
      IDENT_START = /-|#{NMSTART}/

      IDENT_HYPHEN_INTERP = /-+(?=#\{)/
      STRING1_NOINTERP = /\"((?:[^\n\r\f\\"#]|#(?!\{)|#{ESCAPE})*)\"/
      STRING2_NOINTERP = /\'((?:[^\n\r\f\\'#]|#(?!\{)|#{ESCAPE})*)\'/
      STRING_NOINTERP = /#{STRING1_NOINTERP}|#{STRING2_NOINTERP}/

      STATIC_COMPONENT = /#{IDENT}|#{STRING_NOINTERP}|#{HEXCOLOR}|[+-]?#{NUMBER}|\!important/i
      STATIC_VALUE = %r(#{STATIC_COMPONENT}(\s*[\s,\/]\s*#{STATIC_COMPONENT})*(?=[;}]))i
      STATIC_SELECTOR = /(#{NMCHAR}|[ \t]|[,>+*]|[:#.]#{NMSTART}){1,50}([{])/i
    end
  end
end
