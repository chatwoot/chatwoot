# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'

module Mail
  class ContentTransferEncodingField < NamedStructuredField #:nodoc:
    NAME = 'Content-Transfer-Encoding'

    def self.singular?
      true
    end

    def self.normalize_content_transfer_encoding(value)
      case value
      when /7-?bits?/i
        '7bit'
      when /8-?bits?/i
        '8bit'
      else
        value
      end
    end

    def initialize(value = nil, charset = nil)
      super self.class.normalize_content_transfer_encoding(value), charset
    end

    def element
      @element ||= Mail::ContentTransferEncodingElement.new(value)
    end

    def encoding
      element.encoding
    end

    private
      def do_encode
        "#{name}: #{encoding}\r\n"
      end

      def do_decode
        encoding
      end
  end
end
