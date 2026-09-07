class Email::SenderNameBuilder
  TRANSLATION_KEY = 'conversations.reply.email.header.friendly_name'.freeze

  pattr_initialize [:account!, :sender!, :sender_email!, :sender_name!, :business_name!]

  def build
    address = Mail::Address.new(sender_email)
    address.display_name = localized_display_name(address.address)
    address.format
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    localized_header(sender_email)
  end

  private

  def localized_display_name(email_address)
    localized_header(email_address).sub(mailbox_pattern(email_address), '').strip
  end

  def localized_header(email_address)
    I18n.t(
      TRANSLATION_KEY,
      sender_name: sender_name,
      business_name: business_name,
      from_email: email_address,
      locale: sender_locale
    )
  end

  def mailbox_pattern(email_address)
    /\s*[<«]\s*(?:reply\+)?#{Regexp.escape(email_address)}\s*[>»]\s*/
  end

  def sender_locale
    locale_candidates.find { |locale| valid_locale?(locale) && I18n.exists?(TRANSLATION_KEY, locale, fallback: false) } || I18n.default_locale
  end

  def locale_candidates
    sender_locale = sender.ui_settings&.dig('locale') if sender.is_a?(User)
    [sender_locale, account.locale, I18n.default_locale].compact.map(&:to_s).uniq
  end

  def valid_locale?(locale)
    I18n.available_locales.map(&:to_s).include?(locale)
  end
end
