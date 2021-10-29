module ConversationReplyMailerHelper

  def prepare_mail
    data = {
      to: @contact&.email,
      from: email_imap_enabled ? @channel.imap_email : from_email_with_name,
      reply_to: email_imap_enabled ? @channel.imap_email : reply_email,
      subject: mail_subject,
      message_id: email_imap_enabled ? @conversation.additional_attributes['message_id'] : custom_message_id,
      in_reply_to: in_reply_to_email,
      cc: cc_bcc_emails[0],
      bcc: cc_bcc_emails[1]
    }

    if @inbox.inbox_type == 'Email' && @channel.smtp_enabled
      smtp_settings = {
        address: @channel.smtp_address,
        port: @channel.smtp_port,
        user_name: @channel.smtp_email,
        password: @channel.smtp_password,
        domain: @channel.smtp_domain,
        enable_starttls_auto: @channel.smtp_enable_starttls_auto,
        authentication: @channel.smtp_authentication
      }

      data[:delivery_method] = :smtp
      data[:delivery_method_options] = smtp_settings
    end

    data
  end

end
