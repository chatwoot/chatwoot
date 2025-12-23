# encoding: utf-8
# frozen_string_literal: true
require 'mail/parsers/received_parser'
require 'mail/utilities'
require 'date'

module Mail
  class ReceivedElement #:nodoc:
    attr_reader :info, :date_time

    def initialize(string)
      if Utilities.blank? string
        @date_time = nil
        @info = nil
      else
        received = Mail::Parsers::ReceivedParser.parse(string)
        @date_time = datetime_for(received)
        @info = received.info
      end
    end

    def to_s(*args)
      "#{info}; #{date_time.to_s(*args)}"
    end

    private
      def datetime_for(received)
        ::DateTime.parse("#{received.date} #{received.time}")
      rescue ArgumentError => e
        raise e unless e.message == 'invalid date'
        warn "WARNING: Invalid date field for received element (#{received.date} #{received.time}): #{e.class}: #{e.message}"
        nil
      end
  end
end
