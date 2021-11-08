module ConversationReplyMailerHelper
  def create_payload(cc_bcc_enabled)
    @mail = {
      to: @contact&.email,
      from: email_from,
      reply_to: email_reply_to,
      subject: mail_subject,
      message_id: custom_message_id,
      in_reply_to: in_reply_to_email
    }

    if cc_bcc_enabled
      @mail[:cc] = cc_bcc_emails[0]
      @mail[:bcc] = cc_bcc_emails[1]
    end

    set_delivery_method

    @mail
  end

  private

  def set_delivery_method
    return unless @inbox.inbox_type == 'Email' && @channel.smtp_enabled

    smtp_settings = {
      address: @channel.smtp_address,
      port: @channel.smtp_port,
      user_name: @channel.smtp_email,
      password: @channel.smtp_password,
      domain: @channel.smtp_domain,
      enable_starttls_auto: @channel.smtp_enable_starttls_auto,
      authentication: @channel.smtp_authentication
    }

    @mail[:delivery_method] = :smtp
    @mail[:delivery_method_options] = smtp_settings
  end

  def email_imap_enabled
    @inbox.inbox_type == 'Email' && @channel.imap_enabled
  end

  def email_from
    email_imap_enabled ? @channel.imap_email : from_email_with_name
  end

  def email_reply_to
    email_imap_enabled ? @channel.imap_email : reply_email
  end
end
