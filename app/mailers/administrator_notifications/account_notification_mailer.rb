class AdministratorNotifications::AccountNotificationMailer < AdministratorNotifications::BaseMailer
  def account_deletion_user_initiated(account, reason)
    subject = I18n.t('mailer.administrator_notifications.account_notifications.account_deletion_user_initiated.subject', brand_name: brand_name)
    action_url = settings_url('general')
    meta = {
      'account_name' => account.name,
      'deletion_date' => format_deletion_date(account.custom_attributes['marked_for_deletion_at']),
      'reason' => reason
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def account_deletion_for_inactivity(account, reason)
    subject = I18n.t('mailer.administrator_notifications.account_notifications.account_deletion_for_inactivity.subject', brand_name: brand_name)
    action_url = settings_url('general')
    meta = {
      'account_name' => account.name,
      'deletion_date' => format_deletion_date(account.custom_attributes['marked_for_deletion_at']),
      'reason' => reason
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def contact_import_complete(resource)
    subject = I18n.t('mailer.administrator_notifications.account_notifications.contact_import_complete.subject')

    action_url = if resource.csv_import?
                   settings_url("data/#{resource.id}")
                 elsif resource.failed_records.attached?
                   Rails.application.routes.url_helpers.rails_blob_url(resource.failed_records)
                 else
                   "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{resource.account.id}/contacts"
                 end

    meta = {
      'failed_contacts' => resource.total_records - resource.processed_records,
      'imported_contacts' => resource.processed_records
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def contact_import_failed
    subject = I18n.t('mailer.administrator_notifications.account_notifications.contact_import_failed.subject')
    send_notification(subject)
  end

  def contact_export_complete(file_url, email_to)
    subject = I18n.t('mailer.administrator_notifications.account_notifications.contact_export_complete.subject')
    send_notification(subject, to: email_to, action_url: file_url)
  end

  def automation_rule_disabled(rule)
    subject = I18n.t('mailer.administrator_notifications.account_notifications.automation_rule_disabled.subject')
    action_url = settings_url('automation/list')
    meta = { 'rule_name' => rule.name }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  private

  # Through the resolved brand, not GlobalConfig: this mail is addressed to the account's own
  # administrator, so a subject reading "Chatwoot" over a body that says "Acme" is the account
  # being told its deletion by a name it does not use.
  def brand_name
    brand.name.presence || 'Chatwoot'
  end

  def format_deletion_date(deletion_date_str)
    return 'Unknown' if deletion_date_str.blank?

    Time.zone.parse(deletion_date_str).strftime('%B %d, %Y')
  rescue StandardError
    'Unknown'
  end
end
