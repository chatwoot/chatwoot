# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_message_id_field'

module Mail
  # = In-Reply-To Field
  #
  # The In-Reply-To field inherits from StructuredField and handles the
  # In-Reply-To: header field in the email.
  #
  # Sending in_reply_to to a mail message will instantiate a Mail::Field object that
  # has a InReplyToField as its field type.  This includes all Mail::CommonMessageId
  # module instance metods.
  #
  # Note that, the #message_ids method will return an array of message IDs without the
  # enclosing angle brackets which per RFC are not syntactically part of the message id.
  #
  # Only one InReplyTo field can appear in a header, though it can have multiple
  # Message IDs.
  #
  # == Examples:
  #
  #  mail = Mail.new
  #  mail.in_reply_to = '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail.in_reply_to    #=> '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail[:in_reply_to]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::InReplyToField:0x180e1c4
  #  mail['in_reply_to'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::InReplyToField:0x180e1c4
  #  mail['In-Reply-To'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::InReplyToField:0x180e1c4
  #
  #  mail[:in_reply_to].message_ids #=> ['F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom']
  class InReplyToField < CommonMessageIdField #:nodoc:
    NAME = 'In-Reply-To'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      if value.is_a?(Array)
        super value.join("\r\n\s"), charset
      else
        super
      end
    end
  end
end
