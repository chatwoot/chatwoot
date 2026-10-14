class AdministratorNotifications::CaptainNotificationMailer < AdministratorNotifications::BaseMailer
  def response_usage_alert(consumed:, remaining:)
    subject = I18n.t('administrator_notifications.captain.response_usage_alert.subject')
    action_url = settings_url('billing')
    meta = {
      'account_name' => Current.account.name,
      'consumed' => consumed,
      'remaining' => remaining
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end
end
