# encoding: utf-8
# frozen_string_literal: true

module Mail #:nodoc:
  module Multibyte #:nodoc:
    # Returns a regular expression that matches valid characters in the current encoding
    def self.valid_character
      VALID_CHARACTER[Encoding.default_external.to_s]
    end

    # Returns true if string has valid utf-8 encoding
    def self.is_utf8?(string)
      case string.encoding
      when Encoding::UTF_8
        verify(string)
      when Encoding::ASCII_8BIT, Encoding::US_ASCII
        verify(to_utf8(string))
      else
        false
      end
    end

    # Verifies the encoding of a string
    def self.verify(string)
      string.valid_encoding?
    end

    # Verifies the encoding of the string and raises an exception when it's not valid
    def self.verify!(string)
      raise EncodingError.new("Found characters with invalid encoding") unless verify(string)
    end

    # Removes all invalid characters from the string.
    #
    # Note: this method is a no-op in Ruby 1.9
    def self.clean(string)
      string
    end

    def self.to_utf8(string)
      string.dup.force_encoding(Encoding::UTF_8)
    end
  end
end
