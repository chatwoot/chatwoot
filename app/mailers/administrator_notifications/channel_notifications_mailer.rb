class AdministratorNotifications::ChannelNotificationsMailer < ApplicationMailer
  def slack_disconnect(account)
    return unless smtp_config_set_or_development?

    emails = account.administrators.pluck(:email)
    subject = 'Your Slack integration has expired'
    @action_url = "#{ENV['FRONTEND_URL']}/app/accounts/#{account.id}/settings/integrations/slack"
    send_mail_with_liquid(to: emails, subject: subject) and return
  end
end
