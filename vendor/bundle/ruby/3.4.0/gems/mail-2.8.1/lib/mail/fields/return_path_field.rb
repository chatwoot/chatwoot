# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_address_field'

module Mail
  # 4.4.3.  REPLY-TO / RESENT-REPLY-TO
  #
  #    Note:  The "Return-Path" field is added by the mail  transport
  #           service,  at the time of final deliver.  It is intended
  #           to identify a path back to the orginator  of  the  mes-
  #           sage.   The  "Reply-To"  field  is added by the message
  #           originator and is intended to direct replies.
  #
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
  #
  class ReturnPathField < CommonAddressField #:nodoc:
    NAME = 'Return-Path'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      if value == '<>'
        super nil, charset
      else
        super
      end
    end

    def default
      address
    end

    private
      def do_encode
        "#{name}: <#{address}>\r\n"
      end

      def do_decode
        address
      end
  end
end
