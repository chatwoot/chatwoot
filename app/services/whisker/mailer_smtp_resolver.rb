# [whisker] Resolves Action Mailer SMTP settings for a given account.
# Falls back to the instance-wide ENV/GlobalConfig values when the account
# has no per-account SMTP configuration.
module Whisker
  class MailerSmtpResolver
    attr_reader :account

    def initialize(account = nil)
      @account = account
    end

    def resolve
      return global_settings unless account&.smtp_enabled?

      config = account.smtp_config || {}
      settings = {
        address: config['address'],
        port: config['port'].to_i,
        user_name: config['user_name'].presence,
        password: config['password'].presence,
        authentication: (config['authentication'].presence || 'login').to_sym,
        enable_starttls_auto: bool(config['enable_starttls_auto'], true),
        domain: config['domain'].presence
      }
      settings[:openssl_verify_mode] = config['openssl_verify_mode'].to_sym if config['openssl_verify_mode'].present?
      settings[:ssl] = bool(config['ssl']) if config['ssl'].present?
      settings[:tls] = bool(config['tls']) if config['tls'].present?
      settings[:open_timeout] = config['open_timeout'].to_i if config['open_timeout'].present?
      settings[:read_timeout] = config['read_timeout'].to_i if config['read_timeout'].present?
      settings
    end

    def sender_email
      config = account&.smtp_config || {}
      config['sender_email'].presence || GlobalConfigService.load('MAILER_SENDER_EMAIL', 'Whisker <noreply@whisker.site>')
    end

    private

    def global_settings
      {
        address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
        port: ENV.fetch('SMTP_PORT', 587).to_i,
        user_name: ENV.fetch('SMTP_USERNAME', nil),
        password: ENV.fetch('SMTP_PASSWORD', nil),
        authentication: (ENV.fetch('SMTP_AUTHENTICATION', 'login').presence || 'login').to_sym,
        enable_starttls_auto: bool(ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true), true),
        domain: ENV['SMTP_DOMAIN'].presence
      }
    end

    def bool(value, default = false)
      return default if value.nil?

      ActiveModel::Type::Boolean.new.cast(value)
    end
  end

  # Helper to scope a mail delivery to an account's SMTP configuration.
  # Example: Whisker::Mailer.with_smtp(account) { MyMailer.notify.deliver_now }
  # Note: per-account SMTP applies to synchronous (deliver_now) sends within the block.
  module Mailer
    def self.with_smtp(account)
      previous = Thread.current[:whisker_smtp_settings]
      Thread.current[:whisker_smtp_settings] = Whisker::MailerSmtpResolver.new(account).resolve
      yield
    ensure
      Thread.current[:whisker_smtp_settings] = previous
    end
  end
end
