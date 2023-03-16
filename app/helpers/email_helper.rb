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
end
