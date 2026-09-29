module EmailHelper
  def extract_domain_without_tld(email)
    domain = email.split('@').last
    domain.split('.').first
  end

  def render_email_html(content)
    return '' if content.blank?

    ChatwootMarkdownRenderer.new(content).render_message(hardbreaks: true).to_s
  end

  # Recipient lists reach us comma, semicolon or space separated. Mail::AddressList handles the
  # first two along with display name forms such as `Jane Smith <jane@example.com>`, but not a
  # plain space separated list, so collapse the separators unless a display name needs its spaces.
  def process_email_string(email_string)
    return [] if email_string.blank?

    normalized = email_string.match?(/[<"]/) ? email_string : email_string.strip.gsub(/[\s,;]+/, ',')
    addresses = Mail::AddressList.new(normalized).addresses
    # `a@example.com Jane Doe <b@example.com>` parses as one recipient with the first address
    # swallowed into the display name. Reject that rather than dropping a recipient silently.
    raise StandardError, 'Invalid email address' if addresses.any? { |address| address.display_name.to_s.include?('@') }

    addresses.map(&:address)
  rescue Mail::Field::ParseError
    raise StandardError, 'Invalid email address'
  end

  # Raise a standard error if any email address is invalid
  def validate_email_addresses(emails_to_test)
    emails_to_test&.each do |email|
      raise StandardError, 'Invalid email address' unless email.match?(URI::MailTo::EMAIL_REGEXP)
    end
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

  def normalize_email_body(content)
    content.to_s.gsub("\r\n", "\n")
  end

  def modified_liquid_content(email)
    # This regex is used to match the code blocks in the content
    # We don't want to process liquid in code blocks
    email.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
  end

  def message_drops(conversation)
    {
      'contact' => ContactDrop.new(conversation.contact),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(conversation.inbox),
      'account' => AccountDrop.new(conversation.account)
    }
  end
end
