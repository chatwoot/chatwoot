# -*- coding: utf-8 -*-
module Sass::Script::Value
  # A SassScript object representing a CSS string *or* a CSS identifier.
  class String < Base
    @@interpolation_deprecation = Sass::Deprecation.new

    # The Ruby value of the string.
    #
    # @return [String]
    attr_reader :value

    # Whether this is a CSS string or a CSS identifier.
    # The difference is that strings are written with double-quotes,
    # while identifiers aren't.
    #
    # @return [Symbol] `:string` or `:identifier`
    attr_reader :type

    def self.value(contents)
      contents.gsub("\\\n", "").gsub(/\\(?:([0-9a-fA-F]{1,6})\s?|(.))/) do
        next $2 if $2
        # Handle unicode escapes as per CSS Syntax Level 3 section 4.3.8.
        code_point = $1.to_i(16)
        if code_point == 0 || code_point > 0x10FFFF ||
            (code_point >= 0xD800 && code_point <= 0xDFFF)
          '�'
        else
          [code_point].pack("U")
        end
      end
    end

    # Returns the quoted string representation of `contents`.
    #
    # @options opts :quote [String]
    #   The preferred quote style for quoted strings. If `:none`, strings are
    #   always emitted unquoted. If `nil`, quoting is determined automatically.
    # @options opts :sass [String]
    #   Whether to quote strings for Sass source, as opposed to CSS. Defaults to `false`.
    def self.quote(contents, opts = {})
      quote = opts[:quote]

      # Short-circuit if there are no characters that need quoting.
      unless contents =~ /[\n\\"']|\#\{/
        quote ||= '"'
        return "#{quote}#{contents}#{quote}"
      end

      if quote.nil?
        if contents.include?('"')
          if contents.include?("'")
            quote = '"'
          else
            quote = "'"
          end
        else
          quote = '"'
        end
      end

      # Replace single backslashes with multiples.
      contents = contents.gsub("\\", "\\\\\\\\")

      # Escape interpolation.
      contents = contents.gsub('#{', "\\\#{") if opts[:sass]

      if quote == '"'
        contents = contents.gsub('"', "\\\"")
      else
        contents = contents.gsub("'", "\\'")
      end

      contents = contents.gsub(/\n(?![a-fA-F0-9\s])/, "\\a").gsub("\n", "\\a ")
      "#{quote}#{contents}#{quote}"
    end

    # Creates a new string.
    #
    # @param value [String] See \{#value}
    # @param type [Symbol] See \{#type}
    # @param deprecated_interp_equivalent [String?]
    #   If this was created via a potentially-deprecated string interpolation,
    #   this is the replacement expression that should be suggested to the user.
    def initialize(value, type = :identifier, deprecated_interp_equivalent = nil)
      super(value)
      @type = type
      @deprecated_interp_equivalent = deprecated_interp_equivalent
    end

    # @see Value#plus
    def plus(other)
      other_value = if other.is_a?(Sass::Script::Value::String)
                      other.value
                    else
                      other.to_s(:quote => :none)
                    end
      Sass::Script::Value::String.new(value + other_value, type)
    end

    # @see Value#to_s
    def to_s(opts = {})
      return @value.gsub(/\n\s*/, ' ') if opts[:quote] == :none || @type == :identifier
      String.quote(value, opts)
    end

    # @see Value#to_sass
    def to_sass(opts = {})
      to_s(opts.merge(:sass => true))
    end

    def separator
      check_deprecated_interp
      super
    end

    def to_a
      check_deprecated_interp
      super
    end

    # Prints a warning if this string was created using potentially-deprecated
    # interpolation.
    def check_deprecated_interp
      return unless @deprecated_interp_equivalent

      @@interpolation_deprecation.warn(source_range.file, source_range.start_pos.line, <<WARNING)
\#{} interpolation near operators will be simplified in a future version of Sass.
To preserve the current behavior, use quotes:

  #{@deprecated_interp_equivalent}
WARNING
    end

    def inspect
      String.quote(value)
    end
  end
end
