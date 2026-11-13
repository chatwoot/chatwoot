module EmailAddressParseable
  extend ActiveSupport::Concern

  private

  def parse_email(email_string)
    Mail::Address.new(email_string).address.presence || default_sender_email_address
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    default_sender_email_address
  end

  # Mail::Address quotes the display name when it holds characters like commas,
  # which would otherwise split the header into several mailboxes.
  def format_email_with_name(display_name, email)
    address = Mail::Address.new(email)
    address.display_name = display_name
    address.format
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    "#{display_name} <#{email}>"
  end

  def default_sender_email_address
    Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')).address
  end
end
