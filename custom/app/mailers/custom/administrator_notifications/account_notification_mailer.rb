module Custom::AdministratorNotifications::AccountNotificationMailer
  # Rebrand the account-deletion subject lines (user-facing) to the installation
  # name. Bodies are handled by the liquid overrides under custom/app/views.
  def account_deletion_user_initiated(account, reason)
    subject = "Your #{fork_brand_name} account deletion has been scheduled"
    send_deletion_notification(subject, account, reason)
  end

  def account_deletion_for_inactivity(account, reason)
    subject = "Your #{fork_brand_name} account is scheduled for deletion due to inactivity"
    send_deletion_notification(subject, account, reason)
  end

  private

  def send_deletion_notification(subject, account, reason)
    meta = {
      'account_name' => account.name,
      'deletion_date' => format_deletion_date(account.custom_attributes['marked_for_deletion_at']),
      'reason' => reason
    }
    send_notification(subject, action_url: settings_url('general'), meta: meta)
  end

  def fork_brand_name
    GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Chatwoot'
  end
end
