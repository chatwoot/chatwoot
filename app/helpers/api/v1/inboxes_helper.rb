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
                                user_name: channel_data[:imap_email],
                                password: channel_data[:imap_password],
                                enable_ssl: channel_data[:imap_enable_ssl] }
    end

    Mail.connection do # rubocop:disable:block
    end
  end

  def validate_smtp(channel_data)
    return unless channel_data.key?('smtp_enabled') && channel_data[:smtp_enabled]

    smtp = Net::SMTP.start(channel_data[:smtp_address], channel_data[:smtp_port], channel_data[:smtp_domain], channel_data[:smtp_email],
                           channel_data[:smtp_password], :login)
    smtp.finish unless smtp&.nil?
  end
end
