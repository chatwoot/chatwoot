module ConversationReplyMailerHelper
  def prepare_mail(cc_bcc_enabled)
    @options = {
      to: @contact&.email,
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

    set_delivery_method
    mail(@options)
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

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def email_smtp_enabled
    @inbox.inbox_type == 'Email' && @channel.imap_enabled
  end

  def email_from
    email_smtp_enabled ? @channel.smtp_email : from_email_with_name
  end

  def email_reply_to
    email_smtp_enabled ? @channel.smtp_email : reply_email
  end
end
