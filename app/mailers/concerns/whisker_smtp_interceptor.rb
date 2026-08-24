# [whisker] Per-account SMTP delivery.
# Applies an account's webmail/SMTP configuration to outgoing emails.
# The account id is carried on the mail via the X-Whisker-Account-Id header
# (set in ApplicationMailer), so this also works for async (deliver_later) sends.
# When the header is absent or the account has no SMTP config, delivery is
# untouched (falls back to the global ENV/GlobalConfig SMTP).
class WhiskerSmtpInterceptor
  def self.delivering_email(message)
    account_id = message.header['X-Whisker-Account-Id']&.value
    return unless account_id

    account = Account.find_by(id: account_id)
    return unless account&.smtp_enabled?

    config = account.smtp_config || {}
    settings = Whisker::MailerSmtpResolver.new(account).resolve
    message.delivery_method(:smtp, settings)
    message.from = config['sender_email'] if config['sender_email'].present?
  end
end
