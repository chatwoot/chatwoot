# encoding: utf-8
# frozen_string_literal: true
require 'mail/constants'
require 'socket'

module Mail
  module Utilities
    extend self

    # Returns true if the string supplied is free from characters not allowed as an ATOM
    def atom_safe?( str )
      not Constants::ATOM_UNSAFE === str
    end

    # If the string supplied has ATOM unsafe characters in it, will return the string quoted
    # in double quotes, otherwise returns the string unmodified
    def quote_atom( str )
      atom_safe?( str ) ? str : dquote(str)
    end

    # If the string supplied has PHRASE unsafe characters in it, will return the string quoted
    # in double quotes, otherwise returns the string unmodified
    def quote_phrase( str )
      if str.respond_to?(:force_encoding)
        original_encoding = str.encoding
        ascii_str = str.to_s.dup.force_encoding('ASCII-8BIT')
        if Constants::PHRASE_UNSAFE === ascii_str
          dquote(ascii_str).force_encoding(original_encoding)
        else
          str
        end
      else
        Constants::PHRASE_UNSAFE === str ? dquote(str) : str
      end
    end

    # Returns true if the string supplied is free from characters not allowed as a TOKEN
    def token_safe?( str )
      not Constants::TOKEN_UNSAFE === str
    end

    # If the string supplied has TOKEN unsafe characters in it, will return the string quoted
    # in double quotes, otherwise returns the string unmodified
    def quote_token( str )
      if str.respond_to?(:force_encoding)
        original_encoding = str.encoding
        ascii_str = str.to_s.dup.force_encoding('ASCII-8BIT')
        if token_safe?( ascii_str )
          str
        else
          dquote(ascii_str).force_encoding(original_encoding)
        end
      else
        token_safe?( str ) ? str : dquote(str)
      end
    end

    # Wraps supplied string in double quotes and applies \-escaping as necessary,
    # unless it is already wrapped.
    #
    # Example:
    #
    #  string = 'This is a string'
    #  dquote(string) #=> '"This is a string"'
    #
    #  string = 'This is "a string"'
    #  dquote(string #=> '"This is \"a string\"'
    def dquote( str )
      '"' + unquote(str).gsub(/[\\"]/n) {|s| '\\' + s } + '"'
    end

    # Unwraps supplied string from inside double quotes and
    # removes any \-escaping.
    #
    # Example:
    #
    #  string = '"This is a string"'
    #  unquote(string) #=> 'This is a string'
    #
    #  string = '"This is \"a string\""'
    #  unqoute(string) #=> 'This is "a string"'
    def unquote( str )
      if str =~ /^"(.*?)"$/
        unescape($1)
      else
        str
      end
    end

    # Removes any \-escaping.
    #
    # Example:
    #
    #  string = 'This is \"a string\"'
    #  unescape(string) #=> 'This is "a string"'
    #
    #  string = '"This is \"a string\""'
    #  unescape(string) #=> '"This is "a string""'
    def unescape( str )
      str.gsub(/\\(.)/, '\1')
    end

    # Wraps a string in parenthesis and escapes any that are in the string itself.
    #
    # Example:
    #
    #  paren( 'This is a string' ) #=> '(This is a string)'
    def paren( str )
      Utilities.paren( str )
    end

    # Unwraps a string from being wrapped in parenthesis
    #
    # Example:
    #
    #  str = '(This is a string)'
    #  unparen( str ) #=> 'This is a string'
    def unparen( str )
      if str.start_with?('(') && str.end_with?(')')
        str.slice(1..-2)
      else
        str
      end
    end

    # Wraps a string in angle brackets and escapes any that are in the string itself
    #
    # Example:
    #
    #  bracket( 'This is a string' ) #=> '<This is a string>'
    def bracket( str )
      Utilities.bracket( str )
    end

    # Unwraps a string from being wrapped in parenthesis
    #
    # Example:
    #
    #  str = '<This is a string>'
    #  unbracket( str ) #=> 'This is a string'
    def unbracket( str )
      if str.start_with?('<') && str.end_with?('>')
        str.slice(1..-2)
      else
        str
      end
    end

    # Escape parenthesies in a string
    #
    # Example:
    #
    #  str = 'This is (a) string'
    #  escape_paren( str ) #=> 'This is \(a\) string'
    def escape_paren( str )
      Utilities.escape_paren( str )
    end

    def uri_escape( str )
      uri_parser.escape(str)
    end

    def uri_unescape( str )
      uri_parser.unescape(str)
    end

    def uri_parser
      @uri_parser ||= URI.const_defined?(:DEFAULT_PARSER) ? URI::DEFAULT_PARSER : URI
    end

    # Matches two objects with their to_s values case insensitively
    #
    # Example:
    #
    #  obj2 = "This_is_An_object"
    #  obj1 = :this_IS_an_object
    #  match_to_s( obj1, obj2 ) #=> true
    def match_to_s( obj1, obj2 )
      obj1.to_s.casecmp(obj2.to_s) == 0
    end

    # Capitalizes a string that is joined by hyphens correctly.
    #
    # Example:
    #
    #  string = 'resent-from-field'
    #  capitalize_field( string ) #=> 'Resent-From-Field'
    def capitalize_field( str )
      str.to_s.split("-").map { |v| v.capitalize }.join("-")
    end

    # Takes an underscored word and turns it into a class name
    #
    # Example:
    #
    #  constantize("hello") #=> "Hello"
    #  constantize("hello-there") #=> "HelloThere"
    #  constantize("hello-there-mate") #=> "HelloThereMate"
    def constantize( str )
      str.to_s.split(/[-_]/).map { |v| v.capitalize }.to_s
    end

    # Swaps out all underscores (_) for hyphens (-) good for stringing from symbols
    # a field name.
    #
    # Example:
    #
    #  string = :resent_from_field
    #  dasherize( string ) #=> 'resent-from-field'
    def dasherize( str )
      str.to_s.tr(Constants::UNDERSCORE, Constants::HYPHEN)
    end

    # Swaps out all hyphens (-) for underscores (_) good for stringing to symbols
    # a field name.
    #
    # Example:
    #
    #  string = :resent_from_field
    #  underscoreize ( string ) #=> 'resent_from_field'
    def underscoreize( str )
      str.to_s.downcase.tr(Constants::HYPHEN, Constants::UNDERSCORE)
    end

    def map_lines( str, &block )
      str.each_line.map(&block)
    end

    def map_with_index( enum, &block )
      enum.each_with_index.map(&block)
    end

    def self.binary_unsafe_to_lf(string) #:nodoc:
      string.gsub(/\r\n|\r/, Constants::LF)
    end

    TO_CRLF_REGEX =
      # This 1.9 only regex can save a reasonable amount of time (~20%)
      # by not matching "\r\n" so the string is returned unchanged in
      # the common case.
      Regexp.new("(?<!\r)\n|\r(?!\n)")

    def self.binary_unsafe_to_crlf(string) #:nodoc:
      string.gsub(TO_CRLF_REGEX, Constants::CRLF)
    end

    def self.safe_for_line_ending_conversion?(string) #:nodoc:
      if string.encoding == Encoding::BINARY
        string.ascii_only?
      else
        string.valid_encoding?
      end
    end

    # Convert line endings to \n unless the string is binary. Used for
    # sendmail delivery and for decoding 8bit Content-Transfer-Encoding.
    def self.to_lf(string)
      string = string.to_s
      if safe_for_line_ending_conversion? string
        binary_unsafe_to_lf string
      else
        string
      end
    end

    # Convert line endings to \r\n unless the string is binary. Used for
    # encoding 8bit and base64 Content-Transfer-Encoding and for convenience
    # when parsing emails with \n line endings instead of the required \r\n.
    def self.to_crlf(string)
      string = string.to_s
      if safe_for_line_ending_conversion? string
        binary_unsafe_to_crlf string
      else
        string
      end
    end

    # Returns true if the object is considered blank.
    # A blank includes things like '', '   ', nil,
    # and arrays and hashes that have nothing in them.
    #
    # This logic is mostly shared with ActiveSupport's blank?
    def blank?(value)
      if value.kind_of?(NilClass)
        true
      elsif value.kind_of?(String)
        value !~ /\S/
      else
        value.respond_to?(:empty?) ? value.empty? : !value
      end
    end

    def generate_message_id
      "<#{Mail.random_tag}@#{::Socket.gethostname}.mail>"
    end

    class StrictCharsetEncoder
      def encode(string, charset)
        case charset
        when /utf-?7/i
          Mail::Utilities.decode_utf7(string)
        else
          string.force_encoding(Mail::Utilities.pick_encoding(charset))
        end
      end
    end

    class BestEffortCharsetEncoder
      def encode(string, charset)
        case charset
        when /utf-?7/i
          Mail::Utilities.decode_utf7(string)
        else
          string.force_encoding(pick_encoding(charset))
        end
      end

      private

      def pick_encoding(charset)
        charset = case charset
        when /ansi_x3.110-1983/
          'ISO-8859-1'
        when /Windows-?1258/i # Windows-1258 is similar to 1252
          "Windows-1252"
        else
          charset
        end
        Mail::Utilities.pick_encoding(charset)
      end
    end

    class << self
      attr_accessor :charset_encoder
    end
    self.charset_encoder = BestEffortCharsetEncoder.new

    # Escapes any parenthesis in a string that are unescaped this uses
    # a Ruby 1.9.1 regexp feature of negative look behind
    def Utilities.escape_paren( str )
      re = /(?<!\\)([\(\)])/          # Only match unescaped parens
      str.gsub(re) { |s| '\\' + s }
    end

    def Utilities.paren( str )
      str = ::Mail::Utilities.unparen( str )
      str = escape_paren( str )
      '(' + str + ')'
    end

    def Utilities.escape_bracket( str )
      re = /(?<!\\)([\<\>])/          # Only match unescaped brackets
      str.gsub(re) { |s| '\\' + s }
    end

    def Utilities.bracket( str )
      str = ::Mail::Utilities.unbracket( str )
      str = escape_bracket( str )
      '<' + str + '>'
    end

    def Utilities.decode_base64(str)
      if !str.end_with?("=") && str.length % 4 != 0
        str = str.ljust((str.length + 3) & ~3, "=")
      end
      str.unpack( 'm' ).first
    end

    def Utilities.encode_base64(str)
      [str].pack( 'm' )
    end

    def Utilities.has_constant?(klass, string)
      klass.const_defined?( string, false )
    end

    def Utilities.get_constant(klass, string)
      klass.const_get( string )
    end

    def Utilities.transcode_charset(str, from_encoding, to_encoding = Encoding::UTF_8)
      to_encoding = Encoding.find(to_encoding)
      replacement_char = to_encoding == Encoding::UTF_8 ? '�' : '?'
      charset_encoder.encode(str.dup, from_encoding).encode(to_encoding, :undef => :replace, :invalid => :replace, :replace => replacement_char)
    end

    # From Ruby stdlib Net::IMAP
    def Utilities.encode_utf7(string)
      string.gsub(/(&)|[^\x20-\x7e]+/) do
        if $1
          "&-"
        else
          base64 = [$&.encode(Encoding::UTF_16BE)].pack("m0")
          "&" + base64.delete("=").tr("/", ",") + "-"
        end
      end.force_encoding(Encoding::ASCII_8BIT)
    end

    def Utilities.decode_utf7(utf7)
      utf7.gsub(/&([^-]+)?-/n) do
        if $1
          ($1.tr(",", "/") + "===").unpack("m")[0].encode(Encoding::UTF_8, Encoding::UTF_16BE)
        else
          "&"
        end
      end
    end

    def Utilities.b_value_encode(str, encoding = nil)
      encoding = str.encoding.to_s
      [Utilities.encode_base64(str), encoding]
    end

    def Utilities.b_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Bb]\?(.*)\?\=/m)
      if match
        charset = match[1]
        str = Utilities.decode_base64(match[2])
        str = charset_encoder.encode(str, charset)
      end
      transcode_to_scrubbed_utf8(str)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError, Encoding::InvalidByteSequenceError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def Utilities.q_value_encode(str, encoding = nil)
      encoding = str.encoding.to_s
      [Encodings::QuotedPrintable.encode(str), encoding]
    end

    def Utilities.q_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Qq]\?(.*)\?\=/m)
      if match
        charset = match[1]
        string = match[2].gsub(/_/, '=20')
        # Remove trailing = if it exists in a Q encoding
        string = string.sub(/\=$/, '')
        str = Encodings::QuotedPrintable.decode(string)
        str = charset_encoder.encode(str, charset)
        # We assume that binary strings hold utf-8 directly to work around
        # jruby/jruby#829 which subtly changes String#encode semantics.
        str.force_encoding(Encoding::UTF_8) if str.encoding == Encoding::ASCII_8BIT
      end
      transcode_to_scrubbed_utf8(str)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def Utilities.param_decode(str, encoding)
      str = uri_parser.unescape(str)
      str = charset_encoder.encode(str, encoding) if encoding
      transcode_to_scrubbed_utf8(str)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def Utilities.param_encode(str)
      encoding = str.encoding.to_s.downcase
      language = Configuration.instance.param_encode_language
      "#{encoding}'#{language}'#{uri_parser.escape(str)}"
    end

    def Utilities.uri_parser
      URI::DEFAULT_PARSER
    end

    # Pick a Ruby encoding corresponding to the message charset. Most
    # charsets have a Ruby encoding, but some need manual aliasing here.
    #
    # TODO: add this as a test somewhere:
    #   Encoding.list.map { |e| [e.to_s.upcase == pick_encoding(e.to_s.downcase.gsub("-", "")), e.to_s] }.select {|a,b| !b}
    #   Encoding.list.map { |e| [e.to_s == pick_encoding(e.to_s), e.to_s] }.select {|a,b| !b}
    def Utilities.pick_encoding(charset)
      charset = charset.to_s
      encoding = case charset.downcase

      # ISO-8859-8-I etc. http://en.wikipedia.org/wiki/ISO-8859-8-I
      when /^iso[-_]?8859-(\d+)(-i)?$/
        "ISO-8859-#{$1}"

      # ISO-8859-15, ISO-2022-JP and alike
      when /^iso[-_]?(\d{4})-?(\w{1,2})$/
        "ISO-#{$1}-#{$2}"

      # "ISO-2022-JP-KDDI"  and alike
      when /^iso[-_]?(\d{4})-?(\w{1,2})-?(\w*)$/
        "ISO-#{$1}-#{$2}-#{$3}"

      # UTF-8, UTF-32BE and alike
      when /^utf[\-_]?(\d{1,2})?(\w{1,2})$/
        "UTF-#{$1}#{$2}".gsub(/\A(UTF-(?:16|32))\z/, '\\1BE')

      # Windows-1252 and alike
      when /^windows-?(.*)$/
        "Windows-#{$1}"

      when '8bit'
        Encoding::ASCII_8BIT

      # alternatives/misspellings of us-ascii seen in the wild
      when /^iso[-_]?646(-us)?$/, 'us=ascii'
        Encoding::ASCII

      # Microsoft-specific alias for MACROMAN
      when 'macintosh'
        Encoding::MACROMAN

      # Microsoft-specific alias for CP949 (Korean)
      when 'ks_c_5601-1987'
        Encoding::CP949

      # Wrongly written Shift_JIS (Japanese)
      when 'shift-jis'
        Encoding::Shift_JIS

      # GB2312 (Chinese charset) is a subset of GB18030 (its replacement)
      when 'gb2312'
        Encoding::GB18030

      when 'cp-850'
        Encoding::CP850

      when 'latin2'
        Encoding::ISO_8859_2

      else
        charset
      end

      convert_to_encoding(encoding)
    end

    def Utilities.string_byteslice(str, *args)
      str.byteslice(*args)
    end

    class << self
      private

      def convert_to_encoding(encoding)
        if encoding.is_a?(Encoding)
          encoding
        else
          # Fall back to ASCII for charsets that Ruby doesn't recognize
          begin
            Encoding.find(encoding)
          rescue ArgumentError
            Encoding::BINARY
          end
        end
      end

      def transcode_to_scrubbed_utf8(str)
        decoded = str.encode(Encoding::UTF_8, :undef => :replace, :invalid => :replace, :replace => "�")
        decoded.valid_encoding? ? decoded : decoded.encode(Encoding::UTF_16LE, :invalid => :replace, :replace => "�").encode(Encoding::UTF_8)
      end
    end
  end
end
