module ConversationReplyMailerHelper
  def prepare_mail(cc_bcc_enabled)
    @options = {
      to: to_emails,
      from: email_from,
      reply_to: email_reply_to,
      subject: mail_subject,
      message_id: custom_message_id,
      in_reply_to: in_reply_to_email
    }

    if cc_bcc_enabled
      @options[:cc] = cc_bcc_emails[0]
      @options[:bcc] = cc_bcc_emails[1]
    end
    ms_smtp_settings
    google_smtp_settings
    set_delivery_method

    # Email type detection logic:
    # - email_reply: Sets @message with a single message
    # - Other actions: Set @messages with a collection of messages
    #
    # So this check implicitly determines we're handling an email_reply
    # and not one of the other email types (summary, transcript, etc.)
    process_attachments_as_files_for_email_reply if @message&.attachments.present?
    mail(@options)
  end

  def process_attachments_as_files_for_email_reply
    # Attachment processing for direct email replies (when replying to a single message)
    #
    # How attachments are handled:
    # 1. Total file size (<20MB): Added directly to the email as proper attachments
    # 2. Total file size (>20MB): Added to @large_attachments to be displayed as links in the email

    @options[:attachments] = []
    @large_attachments = []
    current_total_size = 0

    @message.attachments.each do |attachment|
      raw_data = attachment.file.download
      attachment_name = attachment.file.filename.to_s
      file_size = raw_data.bytesize

      # Attach files directly until we hit 20MB total
      # After reaching 20MB, send remaining files as links
      if current_total_size + file_size <= 20.megabytes
        mail.attachments[attachment_name] = raw_data
        @options[:attachments] << { name: attachment_name }
        current_total_size += file_size
      else
        @large_attachments << attachment
      end
    end
  end

  private

  def google_smtp_settings
    return unless @inbox.email? && @channel.imap_enabled && @inbox.channel.google?

    smtp_settings = base_smtp_settings('smtp.gmail.com')

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def ms_smtp_settings
    return unless @inbox.email? && @channel.imap_enabled && @inbox.channel.microsoft?

    smtp_settings = base_smtp_settings('smtp.office365.com')

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def base_smtp_settings(domain)
    {
      address: domain,
      port: 587,
      user_name: @channel.imap_login,
      password: @channel.provider_config['access_token'],
      domain: domain,
      tls: false,
      enable_starttls_auto: true,
      openssl_verify_mode: 'none',
      open_timeout: 15,
      read_timeout: 15,
      authentication: 'xoauth2'
    }
  end

  def set_delivery_method
    return unless @inbox.inbox_type == 'Email' && @channel.smtp_enabled

    smtp_settings = {
      address: @channel.smtp_address,
      port: @channel.smtp_port,
      user_name: @channel.smtp_login,
      password: @channel.smtp_password,
      domain: @channel.smtp_domain,
      tls: @channel.smtp_enable_ssl_tls,
      enable_starttls_auto: @channel.smtp_enable_starttls_auto,
      openssl_verify_mode: @channel.smtp_openssl_verify_mode,
      authentication: @channel.smtp_authentication
    }

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def email_smtp_enabled
    @inbox.inbox_type == 'Email' && @channel.smtp_enabled
  end

  def email_imap_enabled
    @inbox.inbox_type == 'Email' && @channel.imap_enabled
  end

  def email_oauth_enabled
    @inbox.inbox_type == 'Email' && (@channel.microsoft? || @channel.google?)
  end

  def email_from
    email_oauth_enabled || email_smtp_enabled ? channel_email_with_name : from_email_with_name
  end

  def email_reply_to
    email_imap_enabled ? @channel.email : reply_email
  end

  # Use channel email domain in case of account email domain is not set for custom message_id and in_reply_to
  def channel_email_domain
    return @account.inbound_email_domain if @account.inbound_email_domain.present?

    email = @inbox.channel.try(:email)
    email.present? ? email.split('@').last : raise(StandardError, 'Channel email domain not present.')
  end
end
