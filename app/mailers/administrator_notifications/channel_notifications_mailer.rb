class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = 'Your Facebook page connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = 'Your Instagram connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def tiktok_disconnect(inbox)
    subject = 'Your TikTok connection has expired'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def whatsapp_disconnect(inbox)
    subject = 'Your Whatsapp connection has expired'
    reason = inbox.channel.provider_config['disconnection_reason']
    meta = {}
    meta['disconnection_reason'] = I18n.t("administrator_notifications.whatsapp.disconnection_reasons.#{reason.downcase}") if reason.present?
    send_notification(subject, action_url: inbox_url(inbox), meta: meta)
  end

  def whatsapp_offboarded(inbox)
    subject = I18n.t('administrator_notifications.whatsapp.offboarded.subject')
    send_notification(subject, action_url: inbox_url(inbox), meta: { 'phone_number' => inbox.channel.phone_number })
  end

  def email_disconnect(inbox)
    subject = 'Your email inbox has been disconnected. Please update the credentials for SMTP/IMAP'
    send_notification(subject, action_url: inbox_url(inbox))
  end
end
