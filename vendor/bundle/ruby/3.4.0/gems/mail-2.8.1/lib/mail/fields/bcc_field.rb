# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_address_field'

module Mail
  # = Blind Carbon Copy Field
  #
  # The Bcc field inherits from StructuredField and handles the Bcc: header
  # field in the email.
  #
  # Sending bcc to a mail message will instantiate a Mail::Field object that
  # has a BccField as its field type.  This includes all Mail::CommonAddress
  # module instance metods.
  #
  # Only one Bcc field can appear in a header, though it can have multiple
  # addresses and groups of addresses.
  #
  # == Examples:
  #
  #  mail = Mail.new
  #  mail.bcc = 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail.bcc    #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:bcc]  #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::BccField:0x180e1c4
  #  mail['bcc'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::BccField:0x180e1c4
  #  mail['Bcc'] #=> '#<Mail::Field:0x180e5e8 @field=#<Mail::BccField:0x180e1c4
  #
  #  mail[:bcc].encoded   #=> ''      # Bcc field does not get output into an email
  #  mail[:bcc].decoded   #=> 'Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net'
  #  mail[:bcc].addresses #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
  #  mail[:bcc].formatted #=> ['Mikel Lindsaar <mikel@test.lindsaar.net>', 'ada@test.lindsaar.net']
  class BccField < CommonAddressField #:nodoc:
    NAME = 'Bcc'

    attr_accessor :include_in_headers

    def initialize(value = nil, charset = nil)
      super
      self.include_in_headers = false
    end

    # Bcc field should not be :encoded by default
    def encoded
      if include_in_headers
        super
      else
        ''
      end
    end
  end
end
