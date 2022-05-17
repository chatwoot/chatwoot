class AgentNotifications::ChannelNotificationMailer < ApplicationMailer
  def facebook_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your Facebook page connection has expired'
    @action_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    emails = agent_emails(inbox)
    send_mail_with_liquid(to: emails, subject: subject) and return
  end

  private

  def agent_emails(inbox)
    inbox.inbox_members.map(&:user).pluck(:email) - admin_emails
  end

  def admin_emails
    Current.account.administrators.pluck(:email)
  end
end
