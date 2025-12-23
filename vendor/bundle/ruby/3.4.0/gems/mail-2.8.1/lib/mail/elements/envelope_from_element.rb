# encoding: utf-8
# frozen_string_literal: true
require 'mail/parsers/envelope_from_parser'
require 'date'

module Mail
  class EnvelopeFromElement #:nodoc:
    attr_reader :date_time, :address

    def initialize(string)
      envelope_from = Mail::Parsers::EnvelopeFromParser.parse(string)
      @address = envelope_from.address
      @date_time = ::DateTime.parse(envelope_from.ctime_date) if envelope_from.ctime_date
    end

    # RFC 4155:
    #   a timestamp indicating the UTC date and time when the message
    #   was originally received, conformant with the syntax of the
    #   traditional UNIX 'ctime' output sans timezone (note that the
    #   use of UTC precludes the need for a timezone indicator);
    def formatted_date_time
      if date_time
        if date_time.respond_to?(:ctime)
          date_time.ctime
        else
          date_time.strftime '%a %b %e %T %Y'
        end
      end
    end

    def to_s
      if date_time
        "#{address} #{formatted_date_time}"
      else
        address
      end
    end
  end
end
