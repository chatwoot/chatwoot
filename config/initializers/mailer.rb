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

  smtp_settings = {}
  if ENV['SMTP_ADDRESS'].present?
    smtp_settings[:address] = ENV['SMTP_ADDRESS']
    smtp_settings[:port] = ENV.fetch('SMTP_PORT', 587).to_i
    smtp_settings[:enable_starttls_auto] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true))
  end

  smtp_settings[:authentication] = ENV['SMTP_AUTHENTICATION'].to_sym if ENV['SMTP_AUTHENTICATION'].present?
  smtp_settings[:domain] = ENV['SMTP_DOMAIN'] if ENV['SMTP_DOMAIN'].present?
  smtp_settings[:user_name] = ENV['SMTP_USERNAME'] if ENV['SMTP_USERNAME'].present?
  smtp_settings[:password] = ENV['SMTP_PASSWORD'] if ENV['SMTP_PASSWORD'].present?
  smtp_settings[:openssl_verify_mode] = ENV['SMTP_OPENSSL_VERIFY_MODE'] if ENV['SMTP_OPENSSL_VERIFY_MODE'].present?
  smtp_settings[:ssl] = ActiveModel::Type::Boolean.new.cast(ENV['SMTP_SSL']) if ENV['SMTP_SSL'].present?
  smtp_settings[:tls] = ActiveModel::Type::Boolean.new.cast(ENV['SMTP_TLS']) if ENV['SMTP_TLS'].present?
  smtp_settings[:open_timeout] = ENV['SMTP_OPEN_TIMEOUT'].to_i if ENV['SMTP_OPEN_TIMEOUT'].present?
  smtp_settings[:read_timeout] = ENV['SMTP_READ_TIMEOUT'].to_i if ENV['SMTP_READ_TIMEOUT'].present?

  smtp_settings.compact!

  # You can use letter opener for your local development by setting the environment variable
  # This should take precedence over SMTP/sendmail in development
  if Rails.env.development? && ENV['LETTER_OPENER'].present?
    config.action_mailer.delivery_method = :letter_opener
  elsif Rails.env.test?
    config.action_mailer.delivery_method = :test
  elsif ENV['POSTMARK_API_TOKEN'].present?
    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = {
      api_token: ENV.fetch('POSTMARK_API_TOKEN')
    }
  elsif ENV['SMTP_ADDRESS'].present?
    config.action_mailer.delivery_method = :smtp
  else
    # Use sendmail if using postfix for email
    config.action_mailer.delivery_method = :sendmail
  end

  config.action_mailer.smtp_settings = smtp_settings

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
