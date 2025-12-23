# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_message_id_field'

module Mail
  # = References Field
  #
  # The References field inherits references StructuredField and handles the References: header
  # field in the email.
  #
  # Sending references to a mail message will instantiate a Mail::Field object that
  # has a ReferencesField as its field type.  This includes all Mail::CommonAddress
  # module instance metods.
  #
  # Note that, the #message_ids method will return an array of message IDs without the
  # enclosing angle brackets which per RFC are not syntactically part of the message id.
  #
  # Only one References field can appear in a header, though it can have multiple
  # Message IDs.
  #
  # == Examples:
  #
  #  mail = Mail.new
  #  mail.references = '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail.references    #=> '<F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom>'
  #  mail[:references]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ReferencesField:0x180e1c4
  #  mail['references'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ReferencesField:0x180e1c4
  #  mail['References'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ReferencesField:0x180e1c4
  #
  #  mail[:references].message_ids #=> ['F6E2D0B4-CC35-4A91-BA4C-C7C712B10C13@test.me.dom']
  class ReferencesField < CommonMessageIdField #:nodoc:
    NAME = 'References'

    def self.singular?
      true
    end

    def initialize(value = nil, charset = nil)
      value = value.join("\r\n\s") if value.is_a?(Array)
      super value, charset
    end
  end
end
