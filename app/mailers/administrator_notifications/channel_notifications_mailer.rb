class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = 'Your Facebook page connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = 'Your Instagram connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def shopee_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = "Your Shopee connection has expired (#{inbox.name})"
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def whatsapp_disconnect(inbox)
    subject = 'Your Whatsapp connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def email_disconnect(inbox)
    subject = 'Your email inbox has been disconnected. Please update the credentials for SMTP/IMAP'
    send_notification(subject, action_url: inbox_url(inbox))
  end
end
