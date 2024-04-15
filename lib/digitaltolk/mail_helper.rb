class Digitaltolk::MailHelper
  INVALID_LOOPIA_EMAIL = '{{email}}@loopia.invalid'
  EMAIL_REGEX = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
  NO_REPLY_EMAIL_REGEX = /\b(?:no-?reply|do-?not-?reply|donotreply)\b/i

  def self.email_from_body(html_content)
    return if html_content.blank?

    match = html_content.to_s.match(EMAIL_REGEX)
    match[0]
  rescue StandardError => e
    Rails.logger.error e
    nil
  end

  def self.from_dt_webflow?(email)
    return false if email.blank?

    email == INVALID_LOOPIA_EMAIL
  rescue StandardError => e
    Rails.logger.error e
    false
  end

  def self.auto_reply?(message)
    return false if message.blank?
    return true if message.auto_reply?

    subject = message.content_attributes.dig(:email, :subject).to_s.downcase
    return true if subject.include?('automatsvar')
    return true if subject.include?('autoresponder')

    subject.include?('autoreply')
  rescue StandardError => e
    Rails.logger.error e
    false
  end

  def self.thank_you_reply?(message)
    return false if message.blank?

    convo = message.conversation
    return false if convo.messages.activity.where("content LIKE '%resolved%'").count <= 1

    content = message.content.to_s[0, 30]
    return false if content.blank?
    return true if content == 'ty'

    %w[thank thanks tack].any? { |str| content.downcase.include?(str) }
  rescue StandardError => e
    Rails.logger.error e
    false
  end

  def self.no_reply_email?(email)
    return false if email.blank?

    email =~ NO_REPLY_EMAIL_REGEX
  rescue StandardError => e
    Rails.logger.error e
    false
  end

  def self.csat_disabled?(message)
    return false if message.blank?

    convo = message.conversation
    return false if convo.blank?
    return true if convo.custom_attributes.dig('block_csat')
    return true if convo.contact.custom_attributes.dig('block_csat')

    last_message = convo.messages.incoming.last
    return true if last_message.blank?

    email = message.conversation.contact.email

    return true if no_reply_email?(email)
    return true if auto_reply?(last_message)
    return true if thank_you_reply?(last_message)

    false
  rescue StandardError => e
    Rails.logger.error e
    false
  end
end
