Rails.application.configure do
  #########################################
  # Configuration Related to Action Mailer
  #########################################

  # We need the application frontend url to be used in our emails
  config.action_mailer.default_url_options = { host: ENV['FRONTEND_URL'] } if ENV['FRONTEND_URL'].present?
  # We load certain mailer templates from our database. This ensures changes to it is reflected immediately
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method =  ENV.fetch('MAILER_DELIVERY_METHOD', ENV['SMTP_ADDRESS'].blank? ? 'sendmail' : 'smtp').to_sym

  if config.action_mailer.delivery_method == :smtp
    smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
      port: ENV.fetch('SMTP_PORT', 587)
    }

    smtp_settings[:authentication] = ENV.fetch('SMTP_AUTHENTICATION', 'login').to_sym if ENV['SMTP_AUTHENTICATION'].present?
    smtp_settings[:domain] = ENV['SMTP_DOMAIN'] if ENV['SMTP_DOMAIN'].present?
    smtp_settings[:user_name] = ENV.fetch('SMTP_USERNAME', nil)
    smtp_settings[:password] = ENV.fetch('SMTP_PASSWORD', nil)
    smtp_settings[:enable_starttls_auto] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true))
    smtp_settings[:openssl_verify_mode] = ENV['SMTP_OPENSSL_VERIFY_MODE'] if ENV['SMTP_OPENSSL_VERIFY_MODE'].present?
    smtp_settings[:ssl] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_SSL', true)) if ENV['SMTP_SSL']
    smtp_settings[:tls] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_TLS', true)) if ENV['SMTP_TLS']
    smtp_settings[:open_timeout] = ENV['SMTP_OPEN_TIMEOUT'].to_i if ENV['SMTP_OPEN_TIMEOUT'].present?
    smtp_settings[:read_timeout] = ENV['SMTP_READ_TIMEOUT'].to_i if ENV['SMTP_READ_TIMEOUT'].present?

    config.action_mailer.smtp_settings = smtp_settings
  end

  if config.action_mailer.delivery_method == :ses_v2
    config.action_mailer.ses_v2_settings = { access_key_id: ENV.fetch('MAILER_SES_ACCESS_KEY_ID', nil),
                                             secret_access_key: ENV.fetch('MAILER_SES_SECRET_ACCESS_KEY', nil),
                                             region: ENV.fetch('MAILER_SES_REGION', nil),
                                             ssl_verify_peer: ActiveModel::Type::Boolean.new.cast(ENV.fetch('MAILER_SES_SSL_VERIFY_PEER', true)) }
  end

  #########################################
  # Configuration Related to Action MailBox
  #########################################

  # Set this to appropriate ingress service for which the options are :
  # :relay for Exim, Postfix, Qmail
  # :mailgun for Mailgun
  # :mandrill for Mandrill
  # :postmark for Postmark
  # :sendgrid for Sendgrid
  # :ses for Amazon SES
  config.action_mailbox.ingress = ENV.fetch('RAILS_INBOUND_EMAIL_SERVICE', 'relay').to_sym

  # Amazon SES ActionMailbox configuration
  config.action_mailbox.ses.subscribed_topic = ENV['ACTION_MAILBOX_SES_SNS_TOPIC'] if ENV['ACTION_MAILBOX_SES_SNS_TOPIC'].present?
end
