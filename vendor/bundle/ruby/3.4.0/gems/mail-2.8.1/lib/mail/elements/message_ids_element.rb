# encoding: utf-8
# frozen_string_literal: true
require 'mail/parsers/message_ids_parser'
require 'mail/utilities'

module Mail
  class MessageIdsElement #:nodoc:
    def self.parse(string)
      new(string).tap(&:message_ids)
    end

    attr_reader :message_ids

    def initialize(string)
      @message_ids = parse(string)
    end

    def message_id
      message_ids.first
    end

    private
      def parse(string)
        if Utilities.blank? string
          []
        else
          Mail::Parsers::MessageIdsParser.parse(string).message_ids
        end
      end
  end
end
