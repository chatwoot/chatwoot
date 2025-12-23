# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_structured_field'

module Mail
  # trace           =       [return]
  #                         1*received
  #
  # return          =       "Return-Path:" path CRLF
  #
  # path            =       ([CFWS] "<" ([CFWS] / addr-spec) ">" [CFWS]) /
  #                         obs-path
  #
  # received        =       "Received:" name-val-list ";" date-time CRLF
  #
  # name-val-list   =       [CFWS] [name-val-pair *(CFWS name-val-pair)]
  #
  # name-val-pair   =       item-name CFWS item-value
  #
  # item-name       =       ALPHA *(["-"] (ALPHA / DIGIT))
  #
  # item-value      =       1*angle-addr / addr-spec /
  #                          atom / domain / msg-id
  class ReceivedField < NamedStructuredField #:nodoc:
    NAME = 'Received'

    def element
      @element ||= Mail::ReceivedElement.new(value)
    end

    def date_time
      @datetime ||= element.date_time
    end

    def info
      element.info
    end

    def formatted_date
      if date_time.respond_to? :strftime and date_time.respond_to? :zone
        date_time.strftime("%a, %d %b %Y %H:%M:%S ") + date_time.zone.delete(':')
      end
    end

    private
      def do_encode
        if Utilities.blank?(value)
          "#{name}: \r\n"
        else
          "#{name}: #{info}; #{formatted_date}\r\n"
        end
      end

      def do_decode
        if Utilities.blank?(value)
          ""
        else
          "#{info}; #{formatted_date}"
        end
      end
  end
end
