module Api::V1::InboxesHelper
  def validate_email_channel(attributes)
    channel_data = permitted_params(attributes)[:channel]

    validate_imap(channel_data)
    validate_smtp(channel_data)
  end

  private

  def validate_imap(channel_data)
    return unless channel_data.key?('imap_enabled') && channel_data[:imap_enabled]

    Mail.defaults do
      retriever_method :imap, { address: channel_data[:imap_address],
                                port: channel_data[:imap_port],
                                user_name: channel_data[:imap_login],
                                password: channel_data[:imap_password],
                                enable_ssl: channel_data[:imap_enable_ssl] }
    end

    Mail.connection do # rubocop:disable:block
    end
  end

  def validate_smtp(channel_data)
    return unless channel_data.key?('smtp_enabled') && channel_data[:smtp_enabled]

    smtp = Net::SMTP.new(channel_data[:smtp_address], channel_data[:smtp_port])

    set_smtp_encryption(channel_data, smtp)
    check_smtp_connection(channel_data, smtp)
  end

  def check_smtp_connection(channel_data, smtp)
    smtp.start(channel_data[:smtp_domain], channel_data[:smtp_login], channel_data[:smtp_password],
               channel_data[:smtp_authentication]&.to_sym || :login)
    smtp.finish unless smtp&.nil?
  end

  def set_smtp_encryption(channel_data, smtp)
    if channel_data[:smtp_enable_ssl_tls]
      set_enable_tls(channel_data, smtp)
    elsif channel_data[:smtp_enable_starttls_auto]
      set_enable_starttls_auto(channel_data, smtp)
    end
  end

  def set_enable_starttls_auto(channel_data, smtp)
    return unless smtp.respond_to?(:enable_starttls_auto)

    if channel_data[:smtp_openssl_verify_mode]
      context = enable_openssl_mode(channel_data[:smtp_openssl_verify_mode])
      smtp.enable_starttls_auto(context)
    else
      smtp.enable_starttls_auto
    end
  end

  def set_enable_tls(channel_data, smtp)
    return unless smtp.respond_to?(:enable_tls)

    if channel_data[:smtp_openssl_verify_mode]
      context = enable_openssl_mode(channel_data[:smtp_openssl_verify_mode])
      smtp.enable_tls(context)
    else
      smtp.enable_tls
    end
  end

  def enable_openssl_mode(smtp_openssl_verify_mode)
    openssl_verify_mode = "OpenSSL::SSL::VERIFY_#{smtp_openssl_verify_mode.upcase}".constantize if smtp_openssl_verify_mode.is_a?(String)
    context = Net::SMTP.default_ssl_context
    context.verify_mode = openssl_verify_mode
    context
  end
end
