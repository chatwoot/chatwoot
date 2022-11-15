class ApplicationMailbox < ActionMailbox::Base
  include MailboxHelper

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_UUID_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i
  CONVERSATION_MESSAGE_ID_PATTERN = %r{conversation/([a-zA-Z0-9\-]*?)/messages/(\d+?)@(\w+\.\w+)}

  def self.reply_mail?
    proc do |inbound_mail|
      reply_uuid_mail?(inbound_mail) || in_reply_to_mail?(inbound_mail)
    end
  end

  def self.support_mail?
    proc do |inbound_mail|
      EmailChannelFinder.new(inbound_mail.mail).perform.present?
    end
  end

  # checks if follow this pattern then send it to reply_mailbox
  # <account/#{@account.id}/conversation/#{@conversation.uuid}@#{@account.inbound_email_domain}>
  def self.in_reply_to_mail?(inbound_mail)
    in_reply_to = inbound_mail.mail.in_reply_to

    in_reply_to.present? && (
      in_reply_to_matches?(in_reply_to) || Message.exists?(source_id: in_reply_to)
    )
  end

  def self.in_reply_to_matches?(in_reply_to)
    Array.wrap(in_reply_to).any? { _1.match?(CONVERSATION_MESSAGE_ID_PATTERN) }
  end

  # checks if follow this pattern  send it to reply_mailbox
  # reply+<conversation-uuid>@<mailer-domain.com>
  def self.reply_uuid_mail?(inbound_mail)
    inbound_mail.mail.to&.any? do |email|
      conversation_uuid = email.split('@')[0]
      conversation_uuid.match?(REPLY_EMAIL_UUID_PATTERN)
    end
  end

  # routing should be defined below the referenced procs

  # routes as a reply to existing conversations
  routing(reply_mail? => :reply)
  # routes as a new conversation in email channel
  routing(support_mail? => :support)
  # catchall
  routing(all: :default)
end
