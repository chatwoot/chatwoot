class TeamNotifications::ContactNotificationMailer < ApplicationMailer
  def contact_export_notification(account)
    return unless smtp_config_set_or_development?

    @action_url = "#{Rails.root}/public/#{account.id}/#{account.name}_#{account.id}_contacts.csv"
    @admins = account.administrators

    send_an_email_to_team(account)
  end

  private

  def send_an_email_to_team(account)
    subject = "Your contact's export file is available to download."
    @action_url = "#{Rails.root}/public/contacts/#{account.name}_#{account.id}_contacts.csv"
    @agent_emails = @admins.pluck(:email)
    send_mail_with_liquid(to: @agent_emails, subject: subject) and return
  end
end
