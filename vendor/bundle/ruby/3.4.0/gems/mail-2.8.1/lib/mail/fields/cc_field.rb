# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_address_field'

module Mail
  # = Carbon Copy Field
  #
  # The Cc field inherits from StructuredField and handles the Cc: header
  # field in the email.
  #
  # Sending cc to a mail message will instantiate a Mail::Field object that
  # has a CcField as its field type.  This includes all Mail::CommonAddress
  # module instance metods.
  #
  # Only one Cc field can appear in a header, though it can have multiple
  # addresses and groups of addresses.
  #
  # == Examples:
  #
  #  mail = Mail.new
  #  mail.cc = 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail.cc    #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:cc]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::CcField:0x180e1c4
  #  mail['cc'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::CcField:0x180e1c4
  #  mail['Cc'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::CcField:0x180e1c4
  #
  #  mail[:cc].encoded   #=> 'Cc: Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net\r\n'
  #  mail[:cc].decoded   #=> 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail[:cc].addresses #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:cc].formatted #=> ['Mikel Lindsaar <mikel@test.lindsaar.net>', 'ada@test.lindsaar.net']
  class CcField < CommonAddressField #:nodoc:
    NAME = 'Cc'
  end
end
