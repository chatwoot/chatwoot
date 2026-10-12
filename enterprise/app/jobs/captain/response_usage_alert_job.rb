class Captain::ResponseUsageAlertJob < ApplicationJob
  self.enqueue_after_transaction_commit = true

  def self.enqueue_for_account(account)
    token = SecureRandom.uuid
    return false unless account.claim_captain_response_usage_alert(token)

    return true if perform_later(account.id, token)

    account.release_captain_response_usage_alert(token)
    false
  rescue StandardError
    account.release_captain_response_usage_alert(token) if token
    raise
  end

  def perform(account_id, token)
    account = Account.find(account_id)
    usage = account.captain_response_usage_alert_details(token)
    return if usage.blank?

    mailer = AdministratorNotifications::CaptainNotificationMailer.with(account: account)
    mailer.response_usage_alert(**usage).deliver_now
    account.mark_captain_response_usage_alerted(token)
  rescue StandardError
    account&.release_captain_response_usage_alert(token)
    raise
  end
end
