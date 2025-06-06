# REVIEW:UP Massive changes in channel_notification_mailer from cv4.1.0, are we using this ourselves?
# REVIEW:UP Contact export shifted to account_notification_mailer
class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = 'Your Facebook page connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = 'Your Instagram connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
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
