class ApplicationMailbox < ActionMailbox::Base
  include MailboxHelper

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_UUID_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i

  # Route all emails to verified channels to the unified reply mailbox
  # The ConversationFinder will determine if it's a reply or new conversation
  routing(
    lambda { |inbound_mail|
      valid_to_address?(inbound_mail) &&
      (reply_uuid_mail?(inbound_mail) || EmailChannelFinder.new(inbound_mail.mail).perform.present?)
    } => :reply
  )

  # catchall
  routing(all: :default)

  class << self
    # checks if follows this pattern: reply+<conversation-uuid>@<mailer-domain.com>
    def reply_uuid_mail?(inbound_mail)
      inbound_mail.mail.to&.any? do |email|
        conversation_uuid = email.split('@')[0]
        conversation_uuid.match?(REPLY_EMAIL_UUID_PATTERN)
      end
    end

    # if mail.to returns a string, then it is a malformed `to` header
    # valid `to` header will be of type Mail::AddressContainer
    # validate if the to address is of type string
    def valid_to_address?(inbound_mail)
      to_address_class = inbound_mail.mail.to&.class
      return true if to_address_class == Mail::AddressContainer

      Rails.logger.error "Email to address header is malformed `#{inbound_mail.mail.to}`"
      false
    end
  end
end
