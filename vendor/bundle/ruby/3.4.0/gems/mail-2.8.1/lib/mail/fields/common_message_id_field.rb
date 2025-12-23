# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'
require 'mail/utilities'

module Mail
  class CommonMessageIdField < NamedStructuredField #:nodoc:
    def element
      @element ||= Mail::MessageIdsElement.new(value)
    end

    def message_id
      element.message_id
    end

    def message_ids
      element.message_ids
    end

    def default
      ids = message_ids
      ids.one? ? ids.first : ids
    end

    def to_s
      decoded.to_s
    end

    private
      def do_encode
        %Q{#{name}: #{formatted_message_ids("\r\n ")}\r\n}
      end

      def do_decode
        formatted_message_ids
      end

      def formatted_message_ids(join = ' ')
        message_ids.map { |m| "<#{m}>" }.join(join) if message_ids.any?
      end
  end
end
