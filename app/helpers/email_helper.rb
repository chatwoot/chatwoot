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
    raise StandardError, 'Invalid email address' if addresses.any? { |address| swallowed_address?(address) }

    addresses.map(&:address)
  rescue Mail::Field::ParseError
    raise StandardError, 'Invalid email address'
  end

  # `a@example.com Jane Doe <b@example.com>` parses as one recipient with the first address
  # swallowed into the display name, and `"Team" jane@example.com John Doe <john@example.com>`
  # drops it from `display_name` altogether. Both lose a recipient silently, so the question is
  # asked of the address's own `raw` source rather than of the parsed name: an `@` in front of
  # the `<...>` address, outside any quoted string, is a recipient that is not being sent to.
  # A quoted display name may hold an `@` of its own -- `"support@example.com" <agent@example.org>`
  # -- and a bare address has no display name to swallow anything into.
  def swallowed_address?(address)
    raw = address.raw.to_s
    angle = raw.index('<')
    return false if angle.nil?

    at_outside_quotes?(raw[0...angle])
  end

  # Is there an `@` in `text` that is not inside a quoted string? Only an odd run of backslashes
  # escapes the quote that follows it, so `"Ops \\"` closes.
  def at_outside_quotes?(text)
    quoted = false
    backslashes = 0
    text.each_char do |c|
      quoted = !quoted if c == '"' && backslashes.even?
      return true if c == '@' && !quoted

      backslashes = c == '\\' ? backslashes + 1 : 0
    end
    false
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
