module EmailHelper
  def extract_domain_without_tld(email)
    domain = email.split('@').last
    domain.split('.').first
  end

  # ref: https://www.rfc-editor.org/rfc/rfc5233.html
  # This is not a  mandatory requirement for email addresses, but it is a common practice.
  # john+test@xyc.com is the same as john@xyc.com
  def normalize_email_with_plus_addressing(email)
    "#{email.split('@').first.split('+').first}@#{email.split('@').last}".downcase
  end

  def parse_email_variables(conversation, email)
    case email
    when /{{.*?}}/
      email_text = email.gsub(/\{\{(.*?)\}\}/) { Regexp.last_match(1) }
      association, attribute = email_text.split('.')
      record = conversation.send(association)
      record.try(attribute)
    when URI::MailTo::EMAIL_REGEXP
      email
    end
  end
end
