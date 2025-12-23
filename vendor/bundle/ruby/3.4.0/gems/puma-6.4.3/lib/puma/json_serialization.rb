# frozen_string_literal: true
require 'stringio'

module Puma

  # Puma deliberately avoids the use of the json gem and instead performs JSON
  # serialization without any external dependencies. In a puma cluster, loading
  # any gem into the puma master process means that operators cannot use a
  # phased restart to upgrade their application if the new version of that
  # application uses a different version of that gem. The json gem in
  # particular is additionally problematic because it leverages native
  # extensions. If the puma master process relies on a gem with native
  # extensions and operators remove gems from disk related to old releases,
  # subsequent phased restarts can fail.
  #
  # The implementation of JSON serialization in this module is not designed to
  # be particularly full-featured or fast. It just has to handle the few places
  # where Puma relies on JSON serialization internally.

  module JSONSerialization
    QUOTE = /"/
    BACKSLASH = /\\/
    CONTROL_CHAR_TO_ESCAPE = /[\x00-\x1F]/ # As required by ECMA-404
    CHAR_TO_ESCAPE = Regexp.union QUOTE, BACKSLASH, CONTROL_CHAR_TO_ESCAPE

    class SerializationError < StandardError; end

    class << self
      def generate(value)
        StringIO.open do |io|
          serialize_value io, value
          io.string
        end
      end

      private

      def serialize_value(output, value)
        case value
        when Hash
          output << '{'
          value.each_with_index do |(k, v), index|
            output << ',' if index != 0
            serialize_object_key output, k
            output << ':'
            serialize_value output, v
          end
          output << '}'
        when Array
          output << '['
          value.each_with_index do |member, index|
            output << ',' if index != 0
            serialize_value output, member
          end
          output << ']'
        when Integer, Float
          output << value.to_s
        when String
          serialize_string output, value
        when true
          output << 'true'
        when false
          output << 'false'
        when nil
          output << 'null'
        else
          raise SerializationError, "Unexpected value of type #{value.class}"
        end
      end

      def serialize_string(output, value)
        output << '"'
        output << value.gsub(CHAR_TO_ESCAPE) do |character|
          case character
          when BACKSLASH
            '\\\\'
          when QUOTE
            '\\"'
          when CONTROL_CHAR_TO_ESCAPE
            '\u%.4X' % character.ord
          end
        end
        output << '"'
      end

      def serialize_object_key(output, value)
        case value
        when Symbol, String
          serialize_string output, value.to_s
        else
          raise SerializationError, "Could not serialize object of type #{value.class} as object key"
        end
      end
    end
  end
end
