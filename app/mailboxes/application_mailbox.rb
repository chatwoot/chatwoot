class ApplicationMailbox < ActionMailbox::Base
  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_USERNAME_PATTERN = /^reply\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i.freeze

  def self.reply_mail?
    proc do |inbound_mail_obj|
      is_a_reply_email = false
      inbound_mail_obj.mail.to.each do |email|
        username = email.split('@')[0]
        match_result = username.match(REPLY_EMAIL_USERNAME_PATTERN)
        if match_result
          is_a_reply_email = true
          break
        end
      end
      is_a_reply_email
    end
  end

  def self.support_mail?
    proc do |inbound_mail_obj|
      is_a_support_email = false
      inbound_mail_obj.mail.to.each do |email|
        channel = Channel::Email.find_by('email = ? OR forward_to_email = ?', email, email)
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

  # routing should be defined below the referenced procs

  # routes as a reply to existing conversations
  routing(reply_mail? => :reply)
  # routes as a new conversation in email channel
  routing(support_mail? => :support)
  routing(catch_all_mail? => :default)
end
