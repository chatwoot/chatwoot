class Captain::ResponseUsageAlertJob < ApplicationJob
  self.enqueue_after_transaction_commit = true

  def perform(account_id)
    account = Account.find(account_id)
    usage = claim_alert(account)
    return if usage.blank?

    mailer = AdministratorNotifications::CaptainNotificationMailer.with(account: account)
    mailer.response_usage_alert(**usage).deliver_now
  end

  private

  def claim_alert(account)
    account.with_lock do
      next unless account.captain_response_usage_alert_required?

      limits = account.usage_limits[:captain][:responses]
      account.mark_captain_response_usage_alerted
      {
        consumed: limits[:consumed],
        remaining: limits[:current_available]
      }
    end
  end
end
