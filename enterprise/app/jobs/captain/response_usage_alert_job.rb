class Captain::ResponseUsageAlertJob < ApplicationJob
  self.enqueue_after_transaction_commit = :never

  def self.enqueue_for_account(account)
    token = SecureRandom.uuid
    return false unless account.claim_captain_response_usage_alert(token)

    enqueue_result = :deferred
    ActiveRecord.after_all_transactions_commit do
      enqueue_result = enqueue_claimed_alert(account.id, token)
    end
    enqueue_result == :deferred || enqueue_result
  rescue StandardError
    account.release_captain_response_usage_alert(token) if token
    raise
  end

  def self.enqueue_claimed_alert(account_id, token)
    return true if perform_later(account_id, token)

    release_claim(account_id, token)
    false
  rescue StandardError
    release_claim(account_id, token)
    raise
  end

  def self.release_claim(account_id, token)
    Account.find_by(id: account_id)&.release_captain_response_usage_alert(token)
  end

  private_class_method :enqueue_claimed_alert, :release_claim

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
