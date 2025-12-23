# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_message_id_field'

module Mail
  #
  # resent-msg-id   =       "Resent-Message-ID:" msg-id CRLF
  class ResentMessageIdField < CommonMessageIdField #:nodoc:
    NAME = 'Resent-Message-ID'
  end
end
