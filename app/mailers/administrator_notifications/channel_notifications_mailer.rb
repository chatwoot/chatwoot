class AdministratorNotifications::ChannelNotificationsMailer < ApplicationMailer # rubocop:disable Metrics/ClassLength
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

  def daily_conversation_report(csv_url, current_date)
    return unless smtp_config_set_or_development?

    subject = "Daily Conversation Report for #{current_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    recipients = admin_emails + [
      'jaideep+chatwootreports@bitespeed.co',
      'aryanm@bitespeed.co',
      'arindam@bitespeed.co'
    ]
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def weekly_conversation_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Conversation Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_conversation_report(csv_url, since_date, until_date, bitespeed_bot)
    return unless smtp_config_set_or_development?

    subject = "Conversation Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    recipients = admin_emails
    recipients += ['jaideep+chatwootdebugreports@bitespeed.co', 'aryanm@bitespeed.co'] if bitespeed_bot
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def daily_custom_attributes_report(csv_url, current_date)
    return unless smtp_config_set_or_development?

    subject = "Daily Custom Attributes Report for #{current_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_custom_attributes_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Custom Attributes Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_attributes_report(csv_url, since_date, until_date, bitespeed_bot)
    return unless smtp_config_set_or_development?

    subject = "Custom Attributes Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    recipients = admin_emails
    recipients += ['jaideep+chatwootdebugreports@bitespeed.co', 'aryanm@bitespeed.co'] if bitespeed_bot
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def daily_agent_report(csv_url, current_date)
    return unless smtp_config_set_or_development?

    subject = "Daily Agent Report for #{current_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_agent_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Agent Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def monthly_agent_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Monthly Agent Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_agent_report(csv_url, since_date, until_date, bitespeed_bot)
    return unless smtp_config_set_or_development?

    subject = "Agent Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    recipients = admin_emails
    recipients += ['jaideep+chatwootdebugreports@bitespeed.co', 'aryanm@bitespeed.co', 'vinayaktrivedi@bitespeed.co'] if bitespeed_bot
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def daily_label_report(csv_url, current_date)
    return unless smtp_config_set_or_development?

    subject = "Daily Label Report for #{current_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_label_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Label Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def monthly_label_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Monthly Label Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_inbox_channel_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Inbox Channel Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def monthly_inbox_channel_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Monthly Inbox Channel Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_inbox_channel_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Inbox Channel Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_agent_level_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Agent Level Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def monthly_agent_level_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Monthly Agent Level Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_agent_level_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Agent Level Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def weekly_bot_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Weekly Bitespeed Bot Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def monthly_bot_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Monthly Bitespeed Bot Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
  end

  def custom_bot_report(csv_url, since_date, until_date)
    return unless smtp_config_set_or_development?

    subject = "Bitespeed Bot Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    send_mail_with_liquid(to: admin_emails + ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co'], subject: subject) and return
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

  def message_report(csv_url, since_date, until_date, recipient_emails)
    return unless smtp_config_set_or_development?

    subject = "Message Report from #{since_date} to #{until_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    recipients = recipient_emails
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def hourly_chat_report(csv_url, report_date)
    return unless smtp_config_set_or_development?

    subject = "Hourly Chat Report for #{report_date} | #{Current.account.name.capitalize}"
    @action_url = csv_url
    @report_date = report_date
    recipients = admin_emails + [
      'jayant@missmosa.in',
      'nitin.bajaj@missmosa.in',
      'jaideep+chatwootreports@bitespeed.co',
      'aryanm@bitespeed.co',
      'arindam@bitespeed.co',
      'jay@procedure.tech'
    ]
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  private

  def admin_emails
    Current.account.administrators.pluck(:email)
  end

  def liquid_locals
    super.merge({ meta: @meta, report_date: @report_date })
  end
end
