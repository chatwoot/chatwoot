class TeamNotifications::ContactNotificationMailer < ApplicationMailer
  def contact_export_notification(account)
    return unless smtp_config_set_or_development?

    @action_url = "#{Rails.root}/public/#{account.name}_#{account.id}_contacts.csv"
    @admins = account.administrators

    send_an_email_to_team
  end

  private

  def send_an_email_to_team
    subject = "Your contact's export file is available to download."
    @action_url = "#{Rails.root}/public/#{account.name}_#{account.id}_contacts.csv"
    @agent_emails = @admins.collect(&:user).pluck(:email)
    send_mail_with_liquid(to: @agent_emails, subject: subject) and return
  end
end
