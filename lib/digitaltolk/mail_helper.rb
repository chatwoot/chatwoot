class Digitaltolk::MailHelper
  INVALID_LOOPIA_EMAIL = '{{email}}@loopia.invalid'
  EMAIL_REGEX = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/

  def self.email_from_body(html_content)
    return if html_content.blank?

    match = html_content.to_s.match(EMAIL_REGEX)
    match.first
  rescue
    nil
  end

  def self.from_dt_webflow?(email)
    return false if email.blank?

    email == INVALID_LOOPIA_EMAIL
  rescue
    false
  end

  def self.auto_reply?(message)
    return false if message.blank?
    return true if message.auto_reply?

    subject = message.content_attributes.dig(:email, :subject).to_s.downcase
    return true if subject.include?('automatsvar')
    return true if subject.include?('autoresponder')

    subject.include?('autoreply')
  rescue
    false
  end
end