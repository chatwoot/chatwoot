class AdministratorNotifications::ChannelNotificationsMailer < ApplicationMailer
  def slack_disconnect
    return unless smtp_config_set_or_development?

    subject = 'Your Slack integration has expired'
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/integrations/slack"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def dialogflow_disconnect
    return unless smtp_config_set_or_development?

    subject = 'Your Dialogflow integration was disconnected'
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def facebook_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your Facebook page connection has expired'
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def whatsapp_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your Whatsapp connection has expired'
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def email_disconnect(inbox)
    return unless smtp_config_set_or_development?

    subject = 'Your email inbox has been disconnected. Please update the credentials for SMTP/IMAP'
    @action_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/inboxes/#{inbox.id}"
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def contact_import_complete(resource)
    return unless smtp_config_set_or_development?

    subject = 'Contact Import Completed'

    @action_url = Rails.application.routes.url_helpers.rails_blob_url(resource.failed_records) if resource.failed_records.attached?
    @action_url ||= "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{resource.account.id}/contacts"
    @meta = {}
    @meta['failed_contacts'] = resource.total_records - resource.processed_records
    @meta['imported_contacts'] = resource.processed_records
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def contact_import_failed
    return unless smtp_config_set_or_development?

    subject = 'Contact Import Failed'

    @meta = {}
    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  def contact_export_complete(file_url, email_to)
    return unless smtp_config_set_or_development?

    @action_url = file_url
    subject = "Your contact's export file is available to download."

    send_mail_with_liquid(to: email_to, subject: subject) and return
  end

  def automation_rule_disabled(rule)
    return unless smtp_config_set_or_development?

    @action_url ||= "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/automation/list"

    subject = 'Automation rule disabled due to validation errors.'.freeze
    @meta = {}
    @meta['rule_name'] = rule.name

    send_mail_with_liquid(to: admin_emails, subject: subject) and return
  end

  private

  def admin_emails
    Current.account.administrators.pluck(:email)
  end

  def liquid_locals
    super.merge({ meta: @meta })
  end
end
