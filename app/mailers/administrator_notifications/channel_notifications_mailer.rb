class AdministratorNotifications::ChannelNotificationsMailer < ApplicationMailer
  def slack_disconnect
    return unless smtp_config_set_or_development?

    subject = 'Your Slack integration has expired'
    @action_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{Current.account.id}/settings/integrations/slack"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def facebook_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your Facebook page connection has expired'
    @action_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def email_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your email inbox has been disconnected. Please update the credentials for SMTP/IMAP'
    @action_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  private

  def admin_emails
    Current.account.administrators.pluck(:email)
  end
end
