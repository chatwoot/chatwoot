module Api::V1::InboxesHelper
  def inbox_name(channel)
    return channel.try(:bot_name) if channel.is_a?(Channel::Telegram)

    permitted_params[:name]
  end

  def validate_email_channel(attributes)
    channel_data = permitted_params(attributes)[:channel]

    validate_imap(channel_data)
    validate_smtp(channel_data)
  end

  private

  def validate_imap(channel_data)
    return unless channel_data.key?('imap_enabled') && channel_data[:imap_enabled]

    # Validate the user-selected auth mechanism before opening the connection.
    authentication = Imap::Authentication.validate_user_configurable!(channel_data[:imap_authentication])

    # Use the same auth adapter as the fetch service so LOGIN uses the IMAP LOGIN command,
    # not SASL AUTH=LOGIN.
    check_imap_connection(channel_data, authentication)
  end

  def validate_smtp(channel_data)
    return unless channel_data.key?('smtp_enabled') && channel_data[:smtp_enabled]

    smtp = Net::SMTP.new(channel_data[:smtp_address], channel_data[:smtp_port])

    set_smtp_encryption(channel_data, smtp)
    check_smtp_connection(channel_data, smtp)
  end

  def check_imap_connection(channel_data, authentication)
    imap = open_imap_connection(channel_data, authentication)
  rescue SocketError => e
    raise StandardError, I18n.t('errors.inboxes.imap.socket_error')
  rescue Net::IMAP::NoResponseError => e
    raise StandardError, I18n.t('errors.inboxes.imap.no_response_error')
  rescue Errno::EHOSTUNREACH => e
    raise StandardError, I18n.t('errors.inboxes.imap.host_unreachable_error')
  rescue Net::OpenTimeout => e
    raise StandardError,
          I18n.t('errors.inboxes.imap.connection_timed_out_error', address: channel_data[:imap_address], port: channel_data[:imap_port])
  rescue Net::IMAP::Error => e
    raise StandardError, I18n.t('errors.inboxes.imap.connection_closed_error')
  rescue StandardError => e
    raise StandardError, e.message
  ensure
    imap.disconnect if imap.present? && !imap.disconnected?
    Rails.logger.error "[Api::V1::InboxesHelper] check_imap_connection failed with #{e.message}" if e.present?
  end

  def open_imap_connection(channel_data, authentication)
    imap = build_imap_connection(channel_data)
    Imap::Authentication.authenticate!(imap, authentication, channel_data[:imap_login], channel_data[:imap_password])
    imap
  end

  def build_imap_connection(channel_data)
    Net::IMAP.new(channel_data[:imap_address], port: channel_data[:imap_port], ssl: channel_data[:imap_enable_ssl])
  end

  def check_smtp_connection(channel_data, smtp)
    smtp.open_timeout = 10
    smtp.start(channel_data[:smtp_domain], channel_data[:smtp_login], channel_data[:smtp_password],
               channel_data[:smtp_authentication]&.to_sym || :login)
    smtp.finish
  rescue Net::SMTPAuthenticationError
    raise StandardError, I18n.t('errors.inboxes.smtp.authentication_error')
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Net::OpenTimeout
    raise StandardError, I18n.t('errors.inboxes.smtp.connection_error')
  rescue OpenSSL::SSL::SSLError
    raise StandardError, I18n.t('errors.inboxes.smtp.ssl_error')
  rescue Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError
    raise StandardError, I18n.t('errors.inboxes.smtp.smtp_error')
  rescue StandardError => e
    raise StandardError, e.message
  end

  def set_smtp_encryption(channel_data, smtp)
    if channel_data[:smtp_enable_ssl_tls]
      set_smtp_ssl_method(smtp, :enable_tls, channel_data[:smtp_openssl_verify_mode])
    elsif channel_data[:smtp_enable_starttls_auto]
      set_smtp_ssl_method(smtp, :enable_starttls_auto, channel_data[:smtp_openssl_verify_mode])
    end
  end

  def set_smtp_ssl_method(smtp, method, openssl_verify_mode)
    return unless smtp.respond_to?(method)

    context = enable_openssl_mode(openssl_verify_mode) if openssl_verify_mode
    context ? smtp.send(method, context) : smtp.send(method)
  end

  def enable_openssl_mode(smtp_openssl_verify_mode)
    openssl_verify_mode = "OpenSSL::SSL::VERIFY_#{smtp_openssl_verify_mode.upcase}".constantize if smtp_openssl_verify_mode.is_a?(String)
    context = Net::SMTP.default_ssl_context
    context.verify_mode = openssl_verify_mode
    context
  end

  def account_channels_method
    {
      'web_widget' => Current.account.web_widgets,
      'api' => Current.account.api_channels,
      'email' => Current.account.email_channels,
      'line' => Current.account.line_channels,
      'telegram' => Current.account.telegram_channels,
      'whatsapp' => Current.account.whatsapp_channels,
      'sms' => Current.account.sms_channels
    }[permitted_params[:channel][:type]]
  end

  def validate_limit
    return unless Current.account.inboxes.count >= Current.account.usage_limits[:inboxes]

    render_payment_required('Account limit exceeded. Upgrade to a higher plan')
  end
end
