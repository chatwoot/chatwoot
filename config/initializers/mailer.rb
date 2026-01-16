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

  # Config related to smtp 
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

  config.action_mailer.delivery_method = :smtp unless Rails.env.test?
  config.action_mailer.smtp_settings = smtp_settings

  # Use sendmail if using postfix for email
  config.action_mailer.delivery_method = :sendmail if ENV['SMTP_ADDRESS'].blank?

  # You can use letter opener for your local development by setting the environment variable
  config.action_mailer.delivery_method = :letter_opener if Rails.env.development? && ENV['LETTER_OPENER']

  # Use Resend HTTPS API if configured (workaround for blocked SMTP ports)
  if ENV['RESEND_API_KEY'].present? && !Rails.env.test? && config.action_mailer.delivery_method != :letter_opener
    config.action_mailer.delivery_method = :resend_api
    Rails.logger.info '✓ Email delivery: Resend HTTPS API (SMTP blocked workaround)'
  else
    delivery_method = config.action_mailer.delivery_method
    case delivery_method
    when :smtp
      address = ENV.fetch('SMTP_ADDRESS', 'localhost')
      port = ENV.fetch('SMTP_PORT', 587)
      Rails.logger.info "✓ Email delivery: SMTP (#{address}:#{port})"
    when :sendmail
      Rails.logger.info '✓ Email delivery: sendmail'
    when :letter_opener
      Rails.logger.info '✓ Email delivery: letter_opener (development)'
    when :test
      Rails.logger.info '✓ Email delivery: test (Rails test environment)'
    else
      Rails.logger.info "✓ Email delivery: #{delivery_method}"
    end
  end

  # Boot logging for debugging mailer configuration
  Rails.logger.info "[MAILER] Rails.env: #{Rails.env}"
  Rails.logger.info "[MAILER] action_mailer.delivery_method: #{config.action_mailer.delivery_method}"
  Rails.logger.info "[MAILER] RESEND_API_KEY present: #{ENV['RESEND_API_KEY'].present?}"

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
