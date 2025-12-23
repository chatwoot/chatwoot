# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_address_field'

module Mail
  # = To Field
  #
  # The To field inherits to StructuredField and handles the To: header
  # field in the email.
  #
  # Sending to to a mail message will instantiate a Mail::Field object that
  # has a ToField as its field type.  This includes all Mail::CommonAddress
  # module instance metods.
  #
  # Only one To field can appear in a header, though it can have multiple
  # addresses and groups of addresses.
  #
  # == Examples:
  #
  #  mail = Mail.new
  #  mail.to = 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail.to    #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:to]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ToField:0x180e1c4
  #  mail['to'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ToField:0x180e1c4
  #  mail['To'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::ToField:0x180e1c4
  #
  #  mail[:to].encoded   #=> 'To: Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net\r\n'
  #  mail[:to].decoded   #=> 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail[:to].addresses #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:to].formatted #=> ['Mikel Lindsaar <mikel@test.lindsaar.net>', 'ada@test.lindsaar.net']
  class ToField < CommonAddressField #:nodoc:
    NAME = 'To'
  end
end
