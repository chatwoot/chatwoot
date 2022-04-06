class ApplicationMailbox < ActionMailbox::Base
  include MailboxHelper

  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_UUID_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i
  CONVERSATION_MESSAGE_ID_PATTERN = %r{conversation/([a-zA-Z0-9\-]*?)/messages/(\d+?)@(\w+\.\w+)}

  def self.reply_mail?
    proc do |inbound_mail_obj|
      is_a_reply_email = false
      inbound_mail_obj.mail.to&.each do |email|
        is_a_reply_email = true if reply_uuid_mail?(email)
      end
      is_a_reply_email = true if in_reply_to_mail?(inbound_mail_obj, is_a_reply_email)

      is_a_reply_email
    end
  end

  def self.support_mail?
    proc do |inbound_mail_obj|
      is_a_support_email = false

      is_a_support_email = true if reply_to_mail?(inbound_mail_obj, is_a_support_email)

      is_a_support_email
    end
  end

  def self.reply_to_mail?(inbound_mail_obj, is_a_support_email)
    return if is_a_support_email

    channel = EmailChannelFinder.new(inbound_mail_obj.mail).perform
    channel.present?
  end

  def self.catch_all_mail?
    proc { |_mail| true }
  end

  # checks if follow this pattern then send it to reply_mailbox
  # <account/#{@account.id}/conversation/#{@conversation.uuid}@#{@account.inbound_email_domain}>
  def self.in_reply_to_mail?(inbound_mail_obj, is_a_reply_email)
    return if is_a_reply_email

    in_reply_to = inbound_mail_obj.mail.in_reply_to

    return false if in_reply_to.blank?

    return true if in_reply_to_matches?(in_reply_to)

    message = Message.find_by(source_id: in_reply_to)
    return true if message.present?

    false
  end

  def self.in_reply_to_matches?(in_reply_to)
    in_reply_to_match = false
    if in_reply_to.is_a?(Array)
      in_reply_to.each do |in_reply_to_mail|
        in_reply_to_match ||= in_reply_to_mail.match(CONVERSATION_MESSAGE_ID_PATTERN)
      end
    else
      in_reply_to_match = in_reply_to.match(CONVERSATION_MESSAGE_ID_PATTERN)
    end
    in_reply_to_match
  end

  # checks if follow this pattern  send it to reply_mailbox
  # reply+<conversation-uuid>@<mailer-domain.com>
  def self.reply_uuid_mail?(email)
    conversation_uuid = email.split('@')[0]
    conversation_uuid.match(REPLY_EMAIL_UUID_PATTERN)
  end

  # routing should be defined below the referenced procs

  # routes as a reply to existing conversations
  routing(reply_mail? => :reply)
  # routes as a new conversation in email channel
  routing(support_mail? => :support)
  routing(catch_all_mail? => :default)
end
