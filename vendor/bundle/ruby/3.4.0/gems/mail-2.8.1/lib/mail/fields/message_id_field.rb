# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_message_id_field'
require 'mail/utilities'

module Mail
  # Only one Message-ID field may appear in a header.
  #
  # Note that parsed Message IDs do not contain their enclosing angle
  # brackets which, per RFC, are not part of the ID.
  #
  #  mail = Mail.new
  #  mail.message_id = '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail.message_id    #=> '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail[:message_id]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::MessageIdField:0x180e1c4
  #  mail['message_id'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::MessageIdField:0x180e1c4
  #  mail['Message-ID'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::MessageIdField:0x180e1c4
  #
  #  mail[:message_id].message_id   #=> 'F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom'
  #  mail[:message_id].message_ids  #=> ['F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom']
  class MessageIdField < CommonMessageIdField #:nodoc:
    NAME = 'Message-ID'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      value = Mail::Utilities.generate_message_id if Utilities.blank?(value)
      super value, charset
    end

    def message_ids
      [message_id]
    end
  end
end
