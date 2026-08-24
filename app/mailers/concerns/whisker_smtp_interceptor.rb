# [whisker] Opt-in per-account SMTP delivery.
# Only takes effect when Thread.current[:whisker_smtp_settings] is set by
# Whisker::Mailer.with_smtp. When unset, mail delivery is untouched (global ENV config).
class WhiskerSmtpInterceptor
  def self.delivering_email(message)
    settings = Thread.current[:whisker_smtp_settings]
    return unless settings.is_a?(Hash) && settings[:address].present?

    message.delivery_method(:smtp, settings)
  end
end
