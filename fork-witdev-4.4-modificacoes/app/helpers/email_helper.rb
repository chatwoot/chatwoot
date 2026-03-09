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
    when modified_liquid_content(email)
      template = Liquid::Template.parse(modified_liquid_content(email))
      template.render(message_drops(conversation))
    when URI::MailTo::EMAIL_REGEXP
      email
    end
  end

  def modified_liquid_content(email)
    # This regex is used to match the code blocks in the content
    # We don't want to process liquid in code blocks
    email.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
  end

  def message_drops(conversation)
    {
      'contact' => ContactDrop.new(conversation.contact)
    }
  end
end
