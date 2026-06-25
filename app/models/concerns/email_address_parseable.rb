module EmailAddressParseable
  extend ActiveSupport::Concern

  private

  def parse_email(email_string)
    Mail::Address.new(email_string).address.presence || default_sender_email_address
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    default_sender_email_address
  end

  def default_sender_email_address
    Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')).address
  end
end
