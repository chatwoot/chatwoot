class TeamNotifications::ContactNotificationMailer < ApplicationMailer
  def contact_export_notification(account, file_url)
    return unless smtp_config_set_or_development?

    @admins = account.administrators

    send_an_email_to_team(account, file_url)
  end

  private

  def send_an_email_to_team(account, file_url)
    subject = "Your contact's export file is available to download."
    @action_url = file_url
    @agent_emails = @admins.pluck(:email)
    send_mail_with_liquid(to: @agent_emails, subject: subject) and return
  end
end
