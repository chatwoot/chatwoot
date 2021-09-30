class ApplicationMailbox < ActionMailbox::Base
  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_USERNAME_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i
  CONVERSATION_UUID_PATTERN = %r{^<account/(\d+?)/conversation/([a-zA-Z0-9\-]*?)@(\w+\.\w+)>$}

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
      inbound_mail_obj.mail.to&.each do |email|
        channel = Channel::Email.find_by('lower(email) = ? OR lower(forward_to_email) = ?', email.downcase, email.downcase)
        if channel.present?
          is_a_support_email = true
          break
        end
      end
      is_a_support_email
    end
  end

  def self.catch_all_mail?
    proc { |_mail| true }
  end

  def self.in_reply_to_mail?(inbound_mail_obj, is_a_reply_email)
    return if is_a_reply_email

    in_reply_to = inbound_mail_obj.mail['In-Reply-To'].value
    return false unless in_reply_to

    in_reply_to.present? && in_reply_to.match(CONVERSATION_UUID_PATTERN)
  end

  def self.reply_uuid_mail?(email)
    username = email.split('@')[0]
    username.match(REPLY_EMAIL_USERNAME_PATTERN)
  end

  # routing should be defined below the referenced procs

  # routes as a reply to existing conversations
  routing(reply_mail? => :reply)
  # routes as a new conversation in email channel
  routing(support_mail? => :support)
  routing(catch_all_mail? => :default)
end
