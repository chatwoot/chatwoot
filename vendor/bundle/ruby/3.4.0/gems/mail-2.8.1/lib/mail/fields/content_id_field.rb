# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'
require 'mail/utilities'

module Mail
  class ContentIdField < NamedStructuredField #:nodoc:
    NAME = 'Content-ID'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      value = Mail::Utilities.generate_message_id if Utilities.blank?(value)
      super value, charset
    end

    def element
      @element ||= Mail::MessageIdsElement.new(value)
    end

    def content_id
      element.message_id
    end

    private
      def do_decode
        "<#{content_id}>"
      end

      def do_encode
        "#{name}: #{do_decode}\r\n"
      end
  end
end
